import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

mixin ChatGroupRepository {
  Future<List<ChatGroup>> listGroups(String workspaceId);
  Future<ChatGroup> getGroup(String workspaceId, String groupId);
  Future<ChatGroup> createGroup(
    String workspaceId, {
    required String name,
    String? description,
    required List<String> memberMembershipIds,
  });
  Future<void> updateGroup(
    String workspaceId,
    String groupId, {
    required String name,
    String? description,
  });
  Future<void> archiveGroup(String workspaceId, String groupId);
  Future<void> addMembers(
    String workspaceId,
    String groupId,
    List<String> membershipIds,
  );
  Future<void> removeMember(
    String workspaceId,
    String groupId,
    String membershipId,
  );
}
