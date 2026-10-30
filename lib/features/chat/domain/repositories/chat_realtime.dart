import 'package:shiftly/features/chat/domain/entities/chat_message.dart';

abstract interface class ChatRealtimeSubscription {
  Future<void> cancel();
}

abstract interface class ChatRealtime {
  ChatRealtimeSubscription subscribeToGroup(
    String groupId,
    void Function() onInsert,
  );
}

abstract interface class ChatLiveRealtime implements ChatRealtime {
  ChatRealtimeSubscription subscribeToMessages(
    String groupId,
    String membershipId,
    void Function(ChatMessage message) onMessage,
    void Function() onResync,
  );
  ChatRealtimeSubscription subscribeToInbox(
    String workspaceId,
    String membershipId,
    void Function() onChanged,
  );
}
