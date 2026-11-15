import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_realtime.dart';

import 'stream_chat_connection.dart';
import 'stream_event_filters.dart';
import 'stream_event_listener.dart';
import 'stream_group_state_subscription.dart';
import 'stream_message_event.dart';

class StreamChatRealtime implements ChatLiveRealtime, ChatGroupStateRealtime {
  StreamChatRealtime(this.connection, this.legacy);
  final StreamChatConnection connection;
  final ChatLiveRealtime legacy;
  @override
  ChatRealtimeSubscription subscribeToGroup(
    String groupId,
    void Function() changed,
  ) => subscribeToMessages(
    groupId,
    connection.scope?.membershipId ?? '',
    (_) => changed(),
    changed,
  );
  @override
  ChatRealtimeSubscription subscribeToMessages(
    String groupId,
    String membershipId,
    void Function(ChatMessage) message,
    void Function() resync,
  ) {
    final old = legacy.subscribeToMessages(
      groupId,
      membershipId,
      message,
      resync,
    );
    return listenStreamEvents(
      connection,
      old,
      (event) => dispatchStreamMessage(event, groupId, message, resync),
      resync,
    );
  }

  @override
  ChatRealtimeSubscription subscribeToInbox(
    String workspaceId,
    String membershipId,
    void Function() changed,
  ) => listenStreamEvents(
    connection,
    legacy.subscribeToInbox(workspaceId, membershipId, changed),
    (event) {
      if (isStreamInboxEvent(event)) {
        changed();
      }
    },
    changed,
  );
  @override
  ChatRealtimeSubscription subscribeToGroupState(
    String groupId,
    void Function() changed,
  ) => subscribeStreamGroupState(connection, legacy, groupId, changed);
}
