import 'package:shiftly/features/chat/data/chat_realtime.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';

class MockChatRepository extends ChatRepository {
  const MockChatRepository();
  @override
  Future<List<ChatGroup>> listGroups(String workspaceId) async => const [];
  @override
  Future<int> unreadCount(String workspaceId) async => 0;
  @override
  Future<ChatGroup> getGroup(String workspaceId, String groupId) =>
      throw UnimplementedError();
  @override
  Future<ChatGroup> createGroup(
    String workspaceId, {
    required String name,
    String? description,
    required List<String> memberMembershipIds,
  }) => throw UnimplementedError();
  @override
  Future<void> updateGroup(
    String workspaceId,
    String groupId, {
    required String name,
    String? description,
  }) => throw UnimplementedError();
  @override
  Future<void> archiveGroup(String workspaceId, String groupId) =>
      throw UnimplementedError();
  @override
  Future<void> addMembers(
    String workspaceId,
    String groupId,
    List<String> membershipIds,
  ) => throw UnimplementedError();
  @override
  Future<void> removeMember(
    String workspaceId,
    String groupId,
    String membershipId,
  ) => throw UnimplementedError();
  @override
  Future<ChatMessagePage> listMessages(
    String workspaceId,
    String groupId, {
    String? cursor,
    int limit = 30,
  }) async => const ChatMessagePage(messages: []);
  @override
  Future<ChatMessage> sendMessage(
    String workspaceId,
    String groupId, {
    required String text,
    required String clientMessageId,
    String? replyToMessageId,
  }) => throw UnimplementedError();
  @override
  Future<void> markRead(
    String workspaceId,
    String groupId,
    String messageId,
  ) async {}
}

class NoopChatRealtime implements ChatRealtime {
  const NoopChatRealtime();
  @override
  ChatRealtimeSubscription subscribeToGroup(
    String groupId,
    void Function() onInsert,
  ) => const _NoopSubscription();
}

class _NoopSubscription implements ChatRealtimeSubscription {
  const _NoopSubscription();
  @override
  Future<void> cancel() async {}
}
