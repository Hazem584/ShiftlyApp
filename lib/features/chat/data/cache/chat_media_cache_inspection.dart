import 'package:shiftly/core/storage/platform_file.dart';
import 'package:shiftly/features/chat/data/cache/chat_media_cache_base.dart';
import 'package:shiftly/features/chat/data/cache/chat_media_cache_eviction.dart';
import 'package:shiftly/features/chat/data/cache/chat_media_inspection.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/services/chat_media_validation.dart';

mixin ChatMediaCacheInspection on ChatMediaCacheBase {
  Future<String?> inspectMediaFile(
    ChatLocalFile file,
    ChatMessage message, {
    bool transformedImage = false,
  }) {
    final operation = inspections.then(
      (_) => _readAndInspect(file, message, transformedImage: transformedImage),
    );
    inspections = operation.then<void>(
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
    final bytes = await file.readAsBytes();
    final mime = transformedImage
        ? ChatMediaValidation.imageMime(bytes)
        : canonicalChatMediaMime(attachment.mimeType);
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
}
