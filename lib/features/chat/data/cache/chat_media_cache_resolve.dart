import 'package:shiftly/core/storage/platform_file.dart';
import 'package:shiftly/features/chat/data/cache/chat_media_cache_base.dart';
import 'package:shiftly/features/chat/data/cache/chat_media_cache_download.dart';
import 'package:shiftly/features/chat/data/cache/chat_media_cache_eviction.dart';
import 'package:shiftly/features/chat/data/cache/chat_media_cache_inspection.dart';
import 'package:shiftly/features/chat/data/cache/chat_media_cache_lookup.dart';
import 'package:shiftly/features/chat/data/cache/chat_media_cache_store.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/domain/services/chat_media_validation.dart';

mixin ChatMediaCacheResolve
    on
        ChatMediaCacheBase,
        ChatMediaCacheEviction,
        ChatMediaCacheDownload,
        ChatMediaCacheInspection,
        ChatMediaCacheLookup {
  @override
  Future<ChatLocalFile> resolve(
    ChatCacheScope scope,
    ChatMessage message,
    ChatRepository repository,
  ) {
    if (!storage.authorized(scope)) {
      return Future.error(StateError('Chat access unavailable'));
    }
    final key = mediaKey(scope, message);
    final existing = inFlight[key];
    if (existing != null) return existing;
    final future = _resolveMedia(scope, message, repository, key);
    inFlight[key] = future;
    return future.whenComplete(() {
      if (identical(inFlight[key], future)) inFlight.remove(key);
    });
  }

  void _validateAttachment(ChatMessage msg) {
    final att = msg.attachment;
    final max = msg.type == 'IMAGE'
        ? ChatMediaValidation.imageMaxBytes
        : ChatMediaValidation.voiceMaxBytes;
    if (att == null ||
        !const ['IMAGE', 'VOICE', 'DOCUMENT'].contains(msg.type) ||
        att.category != msg.type ||
        att.sizeBytes < 1 ||
        att.sizeBytes > max) {
      throw const FormatException('Invalid chat media');
    }
  }

  Future<ChatLocalFile> _resolveMedia(
    ChatCacheScope scope,
    ChatMessage msg,
    ChatRepository repo,
    String key,
  ) async {
    await storage.ready;
    _validateAttachment(msg);
    final rev = storage.revision;
    void check() {
      if (!storage.authorized(scope) || rev != storage.revision) {
        throw StateError('Chat access unavailable');
      }
    }

    final rec = storage.records.record(key);
    return await readCachedMedia(rec, msg, check) ??
        await downloadAndStoreMedia(scope, msg, repo, key, rec, check);
  }
}
