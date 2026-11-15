import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:uuid/uuid.dart';

import 'pending_stream_upload.dart';
import 'stream_chat_connection.dart';

ChatUploadAuthorization prepareStreamUpload(
  Map<String, PendingStreamUpload> pendingUploads,
  StreamChatConnection connection,
  String workspaceId,
  String groupId, {
  required String type,
  required String mimeType,
  required int sizeBytes,
  int? durationMs,
  String? fileName,
}) {
  final scope = connection.scope;
  if (scope == null ||
      scope.workspaceId != workspaceId ||
      !['IMAGE', 'VOICE', 'DOCUMENT'].contains(type) ||
      sizeBytes <= 0 ||
      sizeBytes > 25 * 1024 * 1024) {
    throw const FormatException('Invalid chat upload');
  }
  final id = const Uuid().v4(), token = const Uuid().v4();
  final authorization = ChatUploadAuthorization(
    uploadId: id,
    bucket: 'stream-chat',
    path: '$workspaceId/$groupId/$id',
    uploadToken: token,
    expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 10)),
    expectedMimeType: mimeType,
    expectedSizeBytes: sizeBytes,
  );
  pendingUploads[id] = PendingStreamUpload(
    scope,
    authorization,
    workspaceId,
    groupId,
    type,
    mimeType,
    sizeBytes,
    durationMs,
    fileName,
  );
  return authorization;
}
