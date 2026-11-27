import 'package:shiftly/features/chat/data/chat_realtime.dart';

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
