import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

ChatAttachment? mapStreamAttachment(stream.Attachment? file, String type) =>
    file == null
    ? null
    : ChatAttachment(
        id: (file.extraData['shiftly_attachment_id'] as String?) ?? file.id,
        category: type,
        mimeType: _mime(
          file.extraData['shiftly_mime_type'] as String? ??
              file.mimeType ??
              'application/octet-stream',
        ),
        sizeBytes:
            (file.extraData['shiftly_size_bytes'] as num?)?.toInt() ??
            file.fileSize ??
            1,
        fileName: file.title,
        durationMs: file.extraData['shiftly_duration_ms'] as int?,
      );

String _mime(String value) => switch (value.toLowerCase()) {
  'audio/x-m4a' || 'audio/m4a' || 'video/mp4' => 'audio/mp4',
  'image/jpg' => 'image/jpeg',
  final value => value,
};
