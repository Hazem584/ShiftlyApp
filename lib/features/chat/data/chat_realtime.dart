import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class ChatRealtimeSubscription {
  Future<void> cancel();
}

abstract interface class ChatRealtime {
  ChatRealtimeSubscription subscribeToGroup(
    String groupId,
    void Function() onInsert,
  );
}

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

class _SupabaseChatSubscription implements ChatRealtimeSubscription {
  _SupabaseChatSubscription(this._client, this._channel);
  final SupabaseClient _client;
  final RealtimeChannel _channel;
  bool _cancelled = false;

  @override
  Future<void> cancel() async {
    if (_cancelled) return;
    _cancelled = true;
    await _client.removeChannel(_channel);
  }
}
