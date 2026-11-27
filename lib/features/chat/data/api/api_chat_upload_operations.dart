import 'dart:typed_data';

import 'package:shiftly/features/chat/data/api/api_chat_repository_base.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/entities/chat_upload_cancellation.dart';

mixin ApiChatUploadOperations on ApiChatRepositoryBase {
  @override
  Future<ChatUploadAuthorization> initiateUpload(
    String workspaceId,
    String groupId, {
    required String type,
    required String mimeType,
    required int sizeBytes,
    int? durationMs,
    String? fileName,
  }) => request(() async {
    if (!const ['IMAGE', 'VOICE', 'DOCUMENT'].contains(type) || sizeBytes < 1) {
      throw const FormatException('Invalid upload metadata');
    }
    if ((type != 'VOICE' && durationMs != null) ||
        (type == 'VOICE' && (durationMs == null || durationMs < 1))) {
      throw const FormatException('Invalid upload metadata');
    }
    final response = await dio.post<Object?>(
      '${groupPath(workspaceId, groupId)}/uploads',
      data: {
        'type': type,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
        'durationMs': ?durationMs,
        'fileName': ?fileName,
      },
    );
    return ChatUploadAuthorization.fromJson(
      chatMap(response.data, 'upload authorization'),
    ).withExpectedUpload(mimeType: mimeType, sizeBytes: sizeBytes);
  });

  @override
  Future<void> uploadSigned(
    ChatUploadAuthorization authorization,
    Uint8List bytes,
    String mimeType, {
    void Function(int sent, int total)? onProgress,
    ChatUploadCancellation? cancellation,
  }) => request(() async {
    if (DateTime.now().toUtc().isAfter(authorization.expiresAt)) {
      throw const FormatException('Upload authorization expired');
    }
    if (authorization.expectedMimeType != mimeType ||
        authorization.expectedSizeBytes != bytes.length) {
      throw const FormatException('Upload metadata changed after initiation');
    }
    await signedUploader.upload(
      authorization: authorization,
      bytes: bytes,
      mimeType: mimeType,
      onProgress: onProgress,
      cancellation: cancellation,
    );
  });
}
