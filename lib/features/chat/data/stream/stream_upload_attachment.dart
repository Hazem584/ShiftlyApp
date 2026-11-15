import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import 'pending_stream_upload.dart';

stream.Attachment streamUploadAttachment(String id, PendingStreamUpload value) {
  final url = value.url;
  if (url == null) throw StateError('Upload is not complete.');
  return stream.Attachment(
    id: id,
    type: value.type == 'IMAGE'
        ? 'image'
        : value.type == 'VOICE'
        ? 'audio'
        : 'file',
    title:
        value.fileName ??
        (value.type == 'VOICE' ? 'Voice message' : 'Attachment'),
    imageUrl: value.type == 'IMAGE' ? url : null,
    assetUrl: url,
    uploadState: const stream.UploadState.success(),
    extraData: {
      'shiftly_attachment_id': id,
      'file_size': value.size,
      'shiftly_size_bytes': value.size,
      'mime_type': value.mime,
      'shiftly_mime_type': value.mime,
      if (value.duration != null) 'shiftly_duration_ms': value.duration,
    },
  );
}
