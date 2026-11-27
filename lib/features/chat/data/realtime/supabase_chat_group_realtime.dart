import 'package:shiftly/features/chat/data/realtime/supabase_chat_realtime_base.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_realtime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

mixin SupabaseChatGroupRealtime on SupabaseChatRealtimeBase {
  @override
  ChatRealtimeSubscription subscribeToGroup(
    String groupId,
    void Function() onInsert,
  ) => subscribeGroupChanges(groupId, onInsert, messages: true, receipts: true);

  @override
  ChatRealtimeSubscription subscribeToGroupState(
    String groupId,
    void Function() onChanged,
  ) => subscribeGroupChanges(groupId, onChanged, receipts: true);

  ChatRealtimeSubscription subscribeGroupChanges(
    String id,
    void Function() changed, {
    bool messages = false,
    bool receipts = false,
  }) {
    var cancelled = false;
    final channel = client.channel('chat-access:$id:${sequence++}');
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
    return ChatRealtimeCallbackSubscription(() async {
      cancelled = true;
      await client.removeChannel(channel);
    });
  }
}
