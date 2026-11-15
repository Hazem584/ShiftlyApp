import '../stream_chat_repository_base.dart';

mixin StreamUpdateGroup on StreamChatRepositoryBase {
  @override
  Future<void> updateGroup(
    String workspaceId,
    String groupId, {
    required String name,
    String? description,
  }) => legacy.updateGroup(
    workspaceId,
    groupId,
    name: name,
    description: description,
  );
}
