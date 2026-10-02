import 'package:shiftly/features/chat/data/chat_models.dart';

abstract interface class ChatRepository {
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
  Future<ChatMessagePage> listMessages(
    String workspaceId,
    String groupId, {
    String? cursor,
    int limit = 30,
  });
  Future<ChatMessage> sendMessage(
    String workspaceId,
    String groupId, {
    required String text,
    required String clientMessageId,
    String? replyToMessageId,
  });
  Future<void> markRead(String workspaceId, String groupId, String messageId);
  Future<int> unreadCount(String workspaceId);
}
