part of '../../chat_realtime.dart';

class SupabaseChatRealtime implements ChatRealtime {
  SupabaseChatRealtime(this._client);
  final SupabaseClient _client;
  var _sequence = 0;

  @override
  ChatRealtimeSubscription subscribeToGroup(
    String groupId,
    void Function() onInsert,
  ) {
    final channel = _client
        .channel('chat:$groupId:${_sequence++}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (_) => onInsert(),
        )
        .subscribe((status, _) {
          if (status == RealtimeSubscribeStatus.channelError ||
              status == RealtimeSubscribeStatus.timedOut) {
            onInsert();
          }
        });
    return _SupabaseChatSubscription(_client, channel);
  }
}
