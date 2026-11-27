import 'package:shiftly/features/chat/data/cache/chat_media_cache_base.dart';
import 'package:shiftly/features/chat/data/cache/chat_media_cache_download.dart';
import 'package:shiftly/features/chat/data/cache/chat_media_cache_eviction.dart';
import 'package:shiftly/features/chat/data/cache/chat_media_cache_inspection.dart';
import 'package:shiftly/features/chat/data/cache/chat_media_cache_lookup.dart';
import 'package:shiftly/features/chat/data/cache/chat_media_cache_resolve.dart';

class ChatMediaCache extends ChatMediaCacheBase
    with
        ChatMediaCacheEviction,
        ChatMediaCacheDownload,
        ChatMediaCacheInspection,
        ChatMediaCacheLookup,
        ChatMediaCacheResolve {
  ChatMediaCache(
    super.storage, {
    super.downloadClient,
    super.byteLimit,
    super.retention,
    super.maxTransfers,
  });
}
