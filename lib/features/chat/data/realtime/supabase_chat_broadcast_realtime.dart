import 'dart:async';

import 'package:shiftly/features/chat/data/chat_broadcast_codec.dart';
import 'package:shiftly/features/chat/data/realtime/supabase_chat_group_realtime.dart';
import 'package:shiftly/features/chat/data/realtime/supabase_chat_inbox_realtime.dart';
import 'package:shiftly/features/chat/data/realtime/supabase_chat_realtime_base.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_realtime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

mixin SupabaseChatBroadcastRealtime
    on SupabaseChatRealtimeBase, SupabaseChatGroupRealtime {
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
    final control = subscribeGroupChanges(groupId, onResync);
    final channel = client.channel(
      'chat:$groupId:$membershipId:${sessionId()}',
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
        onResync();
      } else if (isRealtimeChannelFailure(status)) {
        fallback ??= subscribeToGroup(groupId, onResync);
        retry ??= Timer.periodic(const Duration(seconds: 15), (_) {
          if (!cancelled) onResync();
        });
        onResync();
      }
    });
    return ChatRealtimeCallbackSubscription(() async {
      cancelled = true;
      retry?.cancel();
      await fallback?.cancel();
      await control.cancel();
      await client.removeChannel(channel);
    });
  }
}
