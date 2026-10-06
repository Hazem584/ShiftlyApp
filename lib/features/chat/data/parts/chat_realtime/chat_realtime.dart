part of '../../chat_realtime.dart';

abstract interface class ChatRealtime {
  ChatRealtimeSubscription subscribeToGroup(
    String groupId,
    void Function() onInsert,
  );
}
