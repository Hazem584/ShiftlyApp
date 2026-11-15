import 'pending_stream_upload.dart';
import 'stream_chat_connection.dart';

PendingStreamUpload requireStreamUpload(
  Map<String, PendingStreamUpload> pendingUploads,
  StreamChatConnection connection,
  String id,
  String workspaceId,
  String groupId,
) {
  final value = pendingUploads[id];
  if (value == null ||
      value.scope != connection.scope ||
      value.workspaceId != workspaceId ||
      value.groupId != groupId ||
      value.authorization.expiresAt.isBefore(DateTime.now().toUtc())) {
    throw StateError('Upload session expired.');
  }
  return value;
}
