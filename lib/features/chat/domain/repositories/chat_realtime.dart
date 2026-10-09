abstract interface class ChatRealtimeSubscription {
  Future<void> cancel();
}

abstract interface class ChatRealtime {
  ChatRealtimeSubscription subscribeToGroup(
    String groupId,
    void Function() onInsert,
  );
}
