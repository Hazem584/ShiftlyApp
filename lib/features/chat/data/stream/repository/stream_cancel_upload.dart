import '../stream_chat_repository_base.dart';
import '../stream_chat_request.dart';

mixin StreamCancelUpload on StreamChatRepositoryBase {
  @override
  Future<void> cancelUpload(
    String workspaceId,
    String groupId,
    String uploadId,
  ) => streamChatRequest(() async {
    if (!await streamEnabled(workspaceId)) {
      return legacy.cancelUpload(workspaceId, groupId, uploadId);
    }
    return media.cancel(workspaceId, groupId, uploadId);
  });
}
