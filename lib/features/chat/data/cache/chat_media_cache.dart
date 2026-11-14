import 'dart:async';

import 'package:dio/dio.dart';
import 'package:sembast/sembast.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/storage/platform_file.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_database.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_media_store.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/domain/services/chat_media_validation.dart';
import 'package:uuid/uuid.dart';

import 'chat_media_inspection.dart';

class ChatMediaCache implements ChatMediaStore {
  ChatMediaCache(
    this.storage, {
    Dio? downloadClient,
    this.byteLimit = 128 * 1024 * 1024,
    this.retention = const Duration(days: 14),
    this.maxTransfers = 2,
  }) : _downloadClient =
           downloadClient ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 20),
               receiveTimeout: const Duration(seconds: 45),
             ),
           ) {
    storage.listeners.add(_invalidate);
  }
  @override
  final ChatCacheDatabase storage;
  // Deliberately independent of the shared authenticated API client.
  final Dio _downloadClient;
  final int byteLimit;
  final Duration retention;
  final int maxTransfers;
  final Map<String, Future<ChatLocalFile>> _inFlight = {};
  final Map<String, CancelToken> _tokens = {};
  final Map<String, ChatCacheScope> _scopes = {};
  final List<Completer<void>> _waiting = [];
  int _active = 0;
  Future<void> _inspections = Future<void>.value();
  String _key(ChatCacheScope scope, ChatMessage message) =>
      'media:${scope.key}:${message.id}:${message.attachment?.id}';
  @override
  void pin(ChatLocalFile file) => storage.pin(file);
  @override
  void unpin(ChatLocalFile file) => storage.unpin(file);
  @override
  Future<ChatLocalFile> resolve(
    ChatCacheScope scope,
    ChatMessage message,
    ChatRepository repository,
  ) {
    if (!storage.authorized(scope)) {
      return Future.error(StateError('Chat access unavailable'));
    }
    final key = _key(scope, message);
    final existing = _inFlight[key];
    if (existing != null) return existing;
    final future = _resolve(scope, message, repository, key);
    _inFlight[key] = future;
    return future.whenComplete(() {
      if (identical(_inFlight[key], future)) _inFlight.remove(key);
    });
  }

  Future<ChatLocalFile> _resolve(
    ChatCacheScope scope,
    ChatMessage message,
    ChatRepository repository,
    String key,
  ) async {
    await storage.ready;
    final attachment = message.attachment;
    if (attachment == null ||
        !const ['IMAGE', 'VOICE', 'DOCUMENT'].contains(message.type) ||
        attachment.category != message.type ||
        attachment.sizeBytes < 1 ||
        attachment.sizeBytes >
            (message.type == 'IMAGE'
                ? ChatMediaValidation.imageMaxBytes
                : ChatMediaValidation.voiceMaxBytes)) {
      throw const FormatException('Invalid chat media');
    }
    final revision = storage.revision;
    void check() {
      if (!storage.authorized(scope) || revision != storage.revision) {
        throw StateError('Chat access unavailable');
      }
    }

    final record = storage.records.record(key);
    var existing = await record.get(storage.database);
    check();
    if (existing != null &&
        (existing['file'] is! String ||
            !RegExp(r'^[a-f0-9-]+\.bin$')
                .hasMatch(existing['file'] as String))) {
      await record.delete(storage.database);
      existing = null;
    }
    if (existing != null) {
      final file = storage.ownedFile(existing['file'] as String);
      if (await file.exists() &&
          (existing['access'] as int) >=
              DateTime.now().subtract(retention).millisecondsSinceEpoch &&
          existing['digest'] is String &&
          await _inspect(
                file,
                message,
                transformedImage: existing['transformedImage'] == true,
              ) ==
              existing['digest']) {
        check();
        await record.update(storage.database, {
          'access': DateTime.now().millisecondsSinceEpoch,
        });
        return file;
      }
      if (!storage.pins.containsKey(file.path) && await file.exists()) {
        await file.delete();
      }
      await record.delete(storage.database);
    }
    await _acquire();
    final token = CancelToken();
    _tokens[key] = token;
    _scopes[key] = scope;
    final name = '${const Uuid().v4()}.bin';
    final target = ChatLocalFile('${storage.directory.path}/$name');
    final temporary = ChatLocalFile(
      '${storage.directory.path}/${const Uuid().v4()}.part',
    );
    try {
      check();
      var transformedImage = false;
      for (var attempt = 0; attempt < 2; attempt++) {
        final media = await repository.mediaUrl(
          scope.workspaceId,
          scope.groupId,
          message.id,
        );
        check();
        if (media.url.scheme != 'https' || media.url.userInfo.isNotEmpty) {
          throw const FormatException('Invalid media URL');
        }
        transformedImage =
            message.type == 'IMAGE' && media.allowImageTransformation;
        try {
          await _download(
            media.url,
            temporary,
            attachment.sizeBytes,
            attachment.mimeType,
            token,
            transformedImage: transformedImage,
          );
          break;
        } on DioException catch (error) {
          if (attempt == 1 ||
              !const [401, 403].contains(error.response?.statusCode)) {
            rethrow;
          }
        }
      }
      check();
      final digest = await _inspect(
        temporary,
        message,
        transformedImage: transformedImage,
      );
      if (digest == null) {
        throw const FormatException('Invalid chat media');
      }
      check();
      await temporary.rename(target.path);
      check();
      await record.put(storage.database, {
        'kind': 'media',
        'scope': scope.key,
        'user': scope.userId,
        'file': name,
        'size': await target.length(),
        'transformedImage': transformedImage,
        'digest': digest,
        'access': DateTime.now().millisecondsSinceEpoch,
      });
      check();
      pin(target);
      try {
        await evict();
      } finally {
        unpin(target);
      }
      return target;
    } on ApiException catch (error) {
      if (error.statusCode == 403 ||
          (error.statusCode == 404 && error.code == 'CHAT_GROUP_NOT_FOUND')) {
        await storage.revoke(scope);
      }
      rethrow;
    } catch (_) {
      if (await target.exists()) await target.delete();
      rethrow;
    } finally {
      if (await temporary.exists()) await temporary.delete();
      _tokens.remove(key);
      _scopes.remove(key);
      _release();
    }
  }

  Future<void> _download(
    Uri uri,
    ChatLocalFile target,
    int size,
    String mime,
    CancelToken token, {
    bool transformedImage = false,
  }) async {
    final response = await _downloadClient.get<ResponseBody>(
      uri.toString(),
      options: Options(
        responseType: ResponseType.stream,
        followRedirects: false,
      ),
      cancelToken: token,
    );
    final type = response.headers
        .value('content-type')
        ?.split(';')
        .first
        .trim();
    final responseMime = _canonicalMime(type);
    final expectedMime = _canonicalMime(mime);
    const audioTypes = {
      'audio/mp4',
      'audio/webm',
      'audio/ogg',
      'audio/mpeg',
      'audio/aac',
    };
    // Older uploads used .m4a even for WebM/Ogg. Validate their real bytes below.
    final audioContainer =
        audioTypes.contains(expectedMime) && audioTypes.contains(responseMime);
    if (responseMime != null &&
        responseMime != expectedMime &&
        responseMime != 'application/octet-stream' &&
        !audioContainer &&
        !(transformedImage &&
            const [
              'image/jpeg',
              'image/png',
              'image/webp',
            ].contains(responseMime))) {
      throw const FormatException('Invalid media type');
    }
    final body = response.data;
    if (body == null) throw const FormatException('Empty media');
    final sink = target.openWrite();
    var length = 0;
    try {
      await for (final bytes in body.stream) {
        if (token.isCancelled) throw token.cancelError!;
        length += bytes.length;
        if (length >
            (transformedImage ? ChatMediaValidation.imageMaxBytes : size)) {
          throw const FormatException('Invalid media size');
        }
        sink.add(bytes);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
    if (length == 0 || (!transformedImage && length != size)) {
      throw const FormatException('Invalid media size');
    }
  }

  String? _canonicalMime(String? mime) => switch (mime?.toLowerCase()) {
    'audio/x-m4a' || 'audio/m4a' || 'video/mp4' => 'audio/mp4',
    'image/jpg' => 'image/jpeg',
    final value => value,
  };

  Future<String?> _inspect(
    ChatLocalFile file,
    ChatMessage message, {
    bool transformedImage = false,
  }) {
    // Bound CPU work and memory even when a list opens many cached attachments.
    // Wait before reading the next file, not after allocating its byte buffer.
    final operation = _inspections.then(
      (_) => _readAndInspect(file, message, transformedImage: transformedImage),
    );
    _inspections = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<String?> _readAndInspect(
    ChatLocalFile file,
    ChatMessage message, {
    bool transformedImage = false,
  }) async {
    final attachment = message.attachment!;
    if (!await file.exists()) return null;
    final size = await file.length();
    if ((!transformedImage && size != attachment.sizeBytes) ||
        (transformedImage &&
            (message.type != 'IMAGE' ||
                size > ChatMediaValidation.imageMaxBytes))) {
      return null;
    }
    // File/database/plugin access stays here; the worker receives only bytes
    // and metadata. Hash the same snapshot used for content validation.
    final bytes = await file.readAsBytes();
    final mime = transformedImage
        ? ChatMediaValidation.imageMime(bytes)
        : _canonicalMime(attachment.mimeType);
    if (mime == null) return null;
    return inspectChatMedia(
      ChatMediaInspection(
        bytes: bytes,
        type: message.type,
        mimeType: mime,
        sizeBytes: size,
        fileName: attachment.fileName ?? '',
        durationMs: attachment.durationMs ?? 0,
      ),
    );
  }

  Future<void> _acquire() async {
    if (_active < maxTransfers) {
      _active++;
      return;
    }
    final waiter = Completer<void>();
    _waiting.add(waiter);
    await waiter.future;
  }

  void _release() {
    if (_waiting.isNotEmpty) {
      _waiting.removeAt(0).complete();
    } else {
      _active--;
    }
  }

  void _invalidate() {
    for (final entry in _tokens.entries) {
      if (!storage.authorized(_scopes[entry.key]!)) entry.value.cancel();
    }
  }

  @override
  Future<int> size() async {
    final rows = await storage.records.find(
      storage.database,
      finder: Finder(filter: Filter.equals('kind', 'media')),
    );
    return rows.fold<int>(
      0,
      (total, row) => total + (row.value['size'] as int),
    );
  }

  @override
  Future<void> clear() => evict(clear: true);
  Future<void> evict({bool clear = false}) async {
    final rows = await storage.records.find(
      storage.database,
      finder: Finder(
        filter: Filter.equals('kind', 'media'),
        sortOrders: [SortOrder('access')],
      ),
    );
    var total = rows.fold<int>(
      0,
      (sum, row) => sum + (row.value['size'] as int),
    );
    for (final row in rows) {
      final name = row.value['file'];
      if (name is! String || !RegExp(r'^[a-f0-9-]+\.bin$').hasMatch(name)) {
        await storage.records.record(row.key).delete(storage.database);
        continue;
      }
      final file = storage.ownedFile(name);
      if (storage.pins.containsKey(file.path)) continue;
      if (clear ||
          total > byteLimit ||
          (row.value['access'] as int) <
              DateTime.now().subtract(retention).millisecondsSinceEpoch) {
        if (await file.exists()) await file.delete();
        await storage.records.record(row.key).delete(storage.database);
        total -= row.value['size'] as int;
      }
    }
  }

  void close() {
    storage.listeners.remove(_invalidate);
    for (final token in _tokens.values) {
      token.cancel();
    }
    _downloadClient.close(force: true);
  }
}
