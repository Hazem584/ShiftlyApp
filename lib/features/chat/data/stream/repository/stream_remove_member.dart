import '../stream_chat_repository_base.dart';

mixin StreamRemoveMember on StreamChatRepositoryBase {
  @override
  Future<void> removeMember(
    String workspaceId,
    String groupId,
    String membershipId,
  ) => legacy.removeMember(workspaceId, groupId, membershipId);
}
