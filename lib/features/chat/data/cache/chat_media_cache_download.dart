import 'package:dio/dio.dart';
import 'package:shiftly/core/storage/platform_file.dart';
import 'package:shiftly/features/chat/data/cache/chat_media_cache_base.dart';
import 'package:shiftly/features/chat/data/cache/chat_media_cache_eviction.dart';
import 'package:shiftly/features/chat/domain/services/chat_media_validation.dart';

const Set<String> _audioTypes = {
  'audio/mp4',
  'audio/webm',
  'audio/ogg',
  'audio/mpeg',
  'audio/aac',
};
const List<String> _txMimes = ['image/jpeg', 'image/png', 'image/webp'];

mixin ChatMediaCacheDownload on ChatMediaCacheBase {
  Future<void> downloadMediaFile(
    Uri uri,
    ChatLocalFile target,
    int size,
    String mime,
    CancelToken token, {
    bool transformedImage = false,
  }) async {
    final response = await downloadClient.get<ResponseBody>(
      uri.toString(),
      options: Options(
        responseType: ResponseType.stream,
        followRedirects: false,
      ),
      cancelToken: token,
    );
    final raw = response.headers.value('content-type')?.split(';').first.trim();
    final resMime = canonicalChatMediaMime(raw);
    final expMime = canonicalChatMediaMime(mime);
    final audio =
        _audioTypes.contains(expMime) && _audioTypes.contains(resMime);
    final tx = transformedImage && _txMimes.contains(resMime);
    if (resMime != null &&
        resMime != expMime &&
        resMime != 'application/octet-stream' &&
        !audio &&
        !tx) {
      throw const FormatException('Invalid media type');
    }
    final body = response.data;
    if (body == null) throw const FormatException('Empty media');
    final sink = target.openWrite();
    var length = 0;
    final max = transformedImage ? ChatMediaValidation.imageMaxBytes : size;
    try {
      await for (final bytes in body.stream) {
        if (token.isCancelled) throw token.cancelError!;
        length += bytes.length;
        if (length > max) throw const FormatException('Invalid media size');
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
}
