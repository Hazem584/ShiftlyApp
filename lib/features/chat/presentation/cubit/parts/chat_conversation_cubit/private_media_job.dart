part of '../../chat_conversation_cubit.dart';

class _MediaJob {
  _MediaJob({
    required this.clientMessageId,
    required this.mediaType,
    required this.mimeType,
    required this.bytes,
    required this.sizeBytes,
    required this.previewBytes,
    this.durationMs,
  });
  final String clientMessageId;
  final PendingChatMediaType mediaType;
  final String mimeType;
  final Uint8List bytes;
  final int sizeBytes;
  final Uint8List? previewBytes;
  final int? durationMs;
  ChatUploadAuthorization? authorization;
  bool uploaded = false;
  ChatUploadCancellation? cancellation;
  bool running = false;
}
