import '../stream_chat_repository_base.dart';

mixin StreamArchiveGroup on StreamChatRepositoryBase {
  @override
  Future<void> archiveGroup(String workspaceId, String groupId) =>
      legacy.archiveGroup(workspaceId, groupId);
}
