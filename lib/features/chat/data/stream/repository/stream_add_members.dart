import '../stream_chat_repository_base.dart';

mixin StreamAddMembers on StreamChatRepositoryBase {
  @override
  Future<void> addMembers(
    String workspaceId,
    String groupId,
    List<String> membershipIds,
  ) => legacy.addMembers(workspaceId, groupId, membershipIds);
}
