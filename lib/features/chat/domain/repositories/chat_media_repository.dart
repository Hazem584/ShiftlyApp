import 'dart:typed_data';

import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/entities/chat_upload_cancellation.dart';

export 'package:shiftly/features/chat/domain/entities/chat_upload_cancellation.dart';

mixin ChatMediaRepository {
  Future<ChatUploadAuthorization> initiateUpload(
    String workspaceId,
    String groupId, {
    required String type,
    required String mimeType,
    required int sizeBytes,
    int? durationMs,
    String? fileName,
  }) => throw UnsupportedError('Chat media is unavailable');
  Future<void> uploadSigned(
    ChatUploadAuthorization authorization,
    Uint8List bytes,
    String mimeType, {
    void Function(int sent, int total)? onProgress,
    ChatUploadCancellation? cancellation,
  }) => throw UnsupportedError('Chat media is unavailable');
  Future<ChatMessage> finalizeUpload(
    String workspaceId,
    String groupId, {
    required String type,
    required String uploadId,
    required String clientMessageId,
    String? caption,
  }) => throw UnsupportedError('Chat media is unavailable');
  Future<void> cancelUpload(
    String workspaceId,
    String groupId,
    String uploadId,
  ) => throw UnsupportedError('Chat media is unavailable');
  Future<ChatMessage> sendLocation(
    String workspaceId,
    String groupId, {
    required ChatLocation location,
    required String clientMessageId,
  }) => throw UnsupportedError('Location messages are unavailable');
  Future<ChatMediaUrl> mediaUrl(
    String workspaceId,
    String groupId,
    String messageId,
  ) => throw UnsupportedError('Chat media is unavailable');
}
