import 'dart:async';

import 'package:shiftly/features/chat/data/realtime/supabase_chat_realtime_base.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_realtime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

bool isRealtimeChannelFailure(RealtimeSubscribeStatus status) =>
    status == RealtimeSubscribeStatus.channelError ||
    status == RealtimeSubscribeStatus.timedOut ||
    status == RealtimeSubscribeStatus.closed;

mixin SupabaseChatInboxRealtime on SupabaseChatRealtimeBase {
  @override
  ChatRealtimeSubscription subscribeToInbox(
    String workspaceId,
    String membershipId,
    void Function() onChanged,
  ) {
    var cancelled = false;
    Timer? retry;
    final channel = client.channel(
      'chat-inbox:$workspaceId:$membershipId:${sessionId()}',
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
      } else if (isRealtimeChannelFailure(status)) {
        retry ??= Timer.periodic(const Duration(seconds: 15), (_) {
          if (!cancelled) onChanged();
        });
      }
    });
    return ChatRealtimeCallbackSubscription(() async {
      cancelled = true;
      retry?.cancel();
      await client.removeChannel(channel);
    });
  }
}
