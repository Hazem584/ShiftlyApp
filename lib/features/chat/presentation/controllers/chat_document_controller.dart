import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_saver/file_saver.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_media_store.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/domain/services/chat_document_validation.dart';

class ChatDocumentController {
  ChatDocumentController({Dio? downloader})
    : _download =
          downloader ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 45),
            ),
          );
  final Dio _download;

  Future<Uint8List> load({
    required ChatMessage message,
    required ChatRepository repository,
    required FeatureSessionScope session,
    required bool Function() hasAccess,
    ChatMediaStore? cache,
  }) async {
    final attachment = message.attachment;
    if (message.type != 'DOCUMENT' ||
        attachment == null ||
        attachment.category != 'DOCUMENT' ||
        ChatDocumentValidation.mimeForName(attachment.fileName ?? '') != attachment.mimeType ||
        attachment.sizeBytes > ChatDocumentValidation.maxBytes ||
        attachment.sizeBytes < 1) {
      throw const FormatException('Invalid document');
    }
    final key = ChatCacheScope.fromSession(session, message.groupId);
    void check() {
      if (!hasAccess() || (cache != null && !cache.storage.authorized(key))) {
        throw StateError('Chat access unavailable');
      }
    }

    check();
    Uint8List bytes;
    if (cache != null) {
      final file = await cache.resolve(key, message, repository);
      cache.pin(file);
      try {
        bytes = await file.readAsBytes();
      } finally {
        cache.unpin(file);
      }
    } else {
      final media = await repository.mediaUrl(
        session.workspaceId,
        message.groupId,
        message.id,
      );
      check();
      if (media.url.scheme != 'https' || media.url.userInfo.isNotEmpty) {
        throw const FormatException('Invalid media URL');
      }
      final response = await _download.get<ResponseBody>(
        media.url.toString(),
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: false,
        ),
      );
      final body = response.data;
      if (body == null) throw const FormatException('Empty document');
      final buffer = BytesBuilder(copy: false);
      await for (final chunk in body.stream) {
        check();
        if (buffer.length + chunk.length > attachment.sizeBytes) {
          throw const FormatException('Invalid document size');
        }
        buffer.add(chunk);
      }
      bytes = buffer.takeBytes();
    }
    check();
    if (bytes.length != attachment.sizeBytes ||
        !ChatDocumentValidation.valid(bytes, attachment.fileName ?? '')) {
      throw const FormatException('Invalid document content');
    }
    return bytes;
  }

  Future<bool> download(Uint8List bytes, ChatAttachment attachment) async {
    final name = attachment.fileName ?? 'document';
    if (bytes.length != attachment.sizeBytes ||
        ChatDocumentValidation.mimeForName(name) != attachment.mimeType ||
        !ChatDocumentValidation.valid(bytes, name)) {
      throw const FormatException('Invalid document name');
    }
    final dot = name.lastIndexOf('.');
    final saved = await FileSaver.instance.saveAs(
      name: name.substring(0, dot),
      bytes: bytes,
      fileExtension: name.substring(dot + 1),
      mimeType: MimeType.custom,
      customMimeType: attachment.mimeType,
    );
    return saved !=
        null; // Cancellation is not reported as a successful download.
  }
}
