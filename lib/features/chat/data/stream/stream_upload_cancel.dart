import 'pending_stream_upload.dart';
import 'stream_chat_connection.dart';
import 'stream_upload_validation.dart';

Future<void> cancelStreamUpload(
  Map<String, PendingStreamUpload> uploads,
  StreamChatConnection connection,
  String workspaceId,
  String groupId,
  String id,
) async {
  final value = uploads[id];
  if (value == null) return;
  requireStreamUpload(uploads, connection, id, workspaceId, groupId);
  uploads.remove(id);
  if (value.url != null) {
    final channel = await connection.channel(workspaceId, groupId);
    if (value.type == 'IMAGE') {
      await channel.deleteImage(value.url!);
    } else {
      await channel.deleteFile(value.url!);
    }
  }
}
