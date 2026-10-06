part of '../../mock_chat_repository.dart';

class NoopChatRealtime implements ChatRealtime {
  const NoopChatRealtime();
  @override
  ChatRealtimeSubscription subscribeToGroup(
    String groupId,
    void Function() onInsert,
  ) => const _NoopSubscription();
}
