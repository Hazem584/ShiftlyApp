import 'dart:async';

import 'package:shiftly/features/chat/domain/repositories/chat_realtime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

export 'package:shiftly/features/chat/domain/repositories/chat_realtime.dart';

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
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_group_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (_) => onInsert(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'chat_groups',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
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
