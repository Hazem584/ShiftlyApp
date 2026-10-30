import 'dart:async';
import 'dart:convert';

import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_realtime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'chat_broadcast_codec.dart';

export 'package:shiftly/features/chat/domain/repositories/chat_realtime.dart';

class SupabaseChatRealtime implements ChatLiveRealtime {
  SupabaseChatRealtime(this._client);
  final SupabaseClient _client;
  int _sequence = 0;
  String _sessionId() {
    try {
      final token = _client.auth.currentSession?.accessToken;
      final claims = jsonDecode(
        utf8.decode(
          base64Url.decode(base64Url.normalize(token!.split('.')[1])),
        ),
      ) as Map;
      return claims['session_id'] as String;
    } catch (_) {
      return 'unavailable';
    }
  }

  @override
  ChatRealtimeSubscription subscribeToGroup(
    String groupId,
    void Function() onInsert,
  ) => _changes(groupId, onInsert, messages: true, receipts: true);

  ChatRealtimeSubscription _changes(
    String id,
    void Function() changed, {
    bool messages = false,
    bool receipts = false,
  }) {
    var cancelled = false;
    final channel = _client.channel('chat-access:$id:${_sequence++}');
    void listen(String table, String column, PostgresChangeEvent event) {
      channel.onPostgresChanges(
        event: event,
        schema: 'public',
        table: table,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: column,
          value: id,
        ),
        callback: (_) {
          if (!cancelled) changed();
        },
      );
    }

    if (messages) listen('chat_messages', 'group_id', PostgresChangeEvent.all);
    if (receipts) {
      listen('chat_read_states', 'group_id', PostgresChangeEvent.all);
    }
    listen('chat_group_members', 'group_id', PostgresChangeEvent.all);
    listen('chat_groups', 'id', PostgresChangeEvent.update);
    channel.subscribe((status, _) {
      if (!cancelled &&
          (status == RealtimeSubscribeStatus.channelError ||
              status == RealtimeSubscribeStatus.timedOut)) {
        changed();
      }
    });
    return _ChatSubscription(() async {
      cancelled = true;
      await _client.removeChannel(channel);
    });
  }

  @override
  ChatRealtimeSubscription subscribeToMessages(
    String groupId,
    String membershipId,
    void Function(ChatMessage) onMessage,
    void Function() onResync,
  ) {
    var cancelled = false;
    ChatRealtimeSubscription? fallback;
    Timer? retry;
    final control = _changes(groupId, onResync);
    final channel = _client.channel(
      'chat:$groupId:$membershipId:${_sessionId()}',
      opts: const RealtimeChannelConfig(private: true),
    );
    channel.onBroadcast(
      event: 'message',
      callback: (payload) {
        if (cancelled) return;
        try {
          onMessage(ChatBroadcastCodec.decode(payload, groupId));
        } on FormatException {
          onResync();
        }
      },
    );
    channel.subscribe((status, _) {
      if (cancelled) return;
      if (status == RealtimeSubscribeStatus.subscribed) {
        retry?.cancel();
        retry = null;
        final former = fallback;
        fallback = null;
        if (former != null) unawaited(former.cancel());
        onResync(); // Close the initial-subscribe and reconnect gaps.
      } else if (status == RealtimeSubscribeStatus.channelError ||
          status == RealtimeSubscribeStatus.timedOut ||
          status == RealtimeSubscribeStatus.closed) {
        fallback ??= subscribeToGroup(groupId, onResync);
        retry ??= Timer.periodic(const Duration(seconds: 15), (_) {
          if (!cancelled) onResync();
        });
        onResync();
      }
    });
    return _ChatSubscription(() async {
      cancelled = true;
      retry?.cancel();
      await fallback?.cancel();
      await control.cancel();
      await _client.removeChannel(channel);
    });
  }

  @override
  ChatRealtimeSubscription subscribeToInbox(
    String workspaceId,
    String membershipId,
    void Function() onChanged,
  ) {
    var cancelled = false;
    Timer? retry;
    final channel = _client.channel(
      'chat-inbox:$workspaceId:$membershipId:${_sessionId()}',
      opts: const RealtimeChannelConfig(private: true),
    );
    channel.onBroadcast(
      event: 'changed',
      callback: (_) {
        if (!cancelled) onChanged();
      },
    );
    channel.subscribe((status, _) {
      if (cancelled) return;
      if (status == RealtimeSubscribeStatus.subscribed) {
        retry?.cancel();
        retry = null;
        onChanged();
      } else if (status == RealtimeSubscribeStatus.channelError ||
          status == RealtimeSubscribeStatus.timedOut ||
          status == RealtimeSubscribeStatus.closed) {
        retry ??= Timer.periodic(const Duration(seconds: 15), (_) {
          if (!cancelled) onChanged();
        });
      }
    });
    return _ChatSubscription(() async {
      cancelled = true;
      retry?.cancel();
      await _client.removeChannel(channel);
    });
  }
}

class _ChatSubscription implements ChatRealtimeSubscription {
  _ChatSubscription(this._dispose);
  final Future<void> Function() _dispose;
  bool _cancelled = false;
  @override
  Future<void> cancel() async {
    if (_cancelled) return;
    _cancelled = true;
    await _dispose();
  }
}
