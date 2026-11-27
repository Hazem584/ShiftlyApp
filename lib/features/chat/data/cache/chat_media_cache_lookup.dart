import 'package:dio/dio.dart';
import 'package:sembast/sembast.dart';
import 'package:shiftly/core/storage/platform_file.dart';
import 'package:shiftly/features/chat/data/cache/chat_media_cache_base.dart';
import 'package:shiftly/features/chat/data/cache/chat_media_cache_download.dart';
import 'package:shiftly/features/chat/data/cache/chat_media_cache_eviction.dart';
import 'package:shiftly/features/chat/data/cache/chat_media_cache_inspection.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';

mixin ChatMediaCacheLookup
    on
        ChatMediaCacheBase,
        ChatMediaCacheEviction,
        ChatMediaCacheDownload,
        ChatMediaCacheInspection {
  Future<ChatLocalFile?> readCachedMedia(
    RecordRef<String, Map<String, Object?>> record,
    ChatMessage message,
    void Function() check,
  ) async {
    var ex = await record.get(storage.database);
    check();
    final name = ex?['file'];
    if (ex != null && (name is! String || !chatMediaFilePattern.hasMatch(name))) {
      await record.delete(storage.database);
      return null;
    }
    if (ex == null) return null;
    final file = storage.ownedFile(name as String);
    final cutoff = DateTime.now().subtract(retention).millisecondsSinceEpoch;
    final tx = ex['transformedImage'] == true;
    if (await file.exists() &&
        (ex['access'] as int) >= cutoff &&
        ex['digest'] is String &&
        await inspectMediaFile(file, message, transformedImage: tx) ==
            ex['digest']) {
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
    return null;
  }

  Future<bool> fetchMediaWithRetry(
    ChatCacheScope scope,
    ChatMessage msg,
    ChatRepository repo,
    ChatLocalFile temp,
    CancelToken token,
    void Function() check,
  ) async {
    final att = msg.attachment!;
    for (var attempt = 0; attempt < 2; attempt++) {
      final media = await repo.mediaUrl(scope.workspaceId, scope.groupId, msg.id);
      check();
      if (media.url.scheme != 'https' || media.url.userInfo.isNotEmpty) {
        throw const FormatException('Invalid media URL');
      }
      final tx = msg.type == 'IMAGE' && media.allowImageTransformation;
      try {
        await downloadMediaFile(
          media.url,
          temp,
          att.sizeBytes,
          att.mimeType,
          token,
          transformedImage: tx,
        );
        return tx;
      } on DioException catch (e) {
        final c = e.response?.statusCode;
        if (attempt == 1 || (c != 401 && c != 403)) rethrow;
      }
    }
    return false;
  }
}
