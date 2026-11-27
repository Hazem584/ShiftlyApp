import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_realtime.dart';

import '../../domain/entities/chat_inbox_activity.dart';
import 'stream_chat_connection.dart';
import 'stream_event_listener.dart';
import 'stream_group_state_subscription.dart';
import 'stream_inbox_subscription.dart';
import 'stream_message_event.dart';

class StreamChatRealtime implements ChatInboxRealtime, ChatGroupStateRealtime {
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
  ) => listenStreamEvents(
    connection,
    legacy.subscribeToMessages(groupId, membershipId, message, resync),
    (event) => dispatchStreamMessage(event, groupId, message, resync),
    resync,
  );

  @override
  ChatRealtimeSubscription subscribeToInbox(
    String workspaceId,
    String membershipId,
    void Function() changed,
  ) => subscribeToInboxActivity(
    workspaceId,
    membershipId,
    (_) => changed(),
    changed,
  );

  @override
  ChatRealtimeSubscription subscribeToInboxActivity(
    String workspaceId,
    String membershipId,
    void Function(ChatInboxActivity) onActivity,
    void Function() onResync,
  ) => subscribeStreamInbox(
    connection,
    legacy.subscribeToInbox(workspaceId, membershipId, onResync),
    onActivity,
    onResync,
  );

  @override
  ChatRealtimeSubscription subscribeToGroupState(
    String groupId,
    void Function() changed,
  ) => subscribeStreamGroupState(connection, legacy, groupId, changed);
}
