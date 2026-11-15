import 'package:shiftly/features/chat/domain/repositories/chat_realtime.dart';

import 'stream_chat_connection.dart';
import 'stream_event_filters.dart';
import 'stream_event_listener.dart';

ChatRealtimeSubscription subscribeStreamGroupState(
  StreamChatConnection connection,
  ChatLiveRealtime legacy,
  String groupId,
  void Function() changed,
) => listenStreamEvents(
  connection,
  (legacy as ChatGroupStateRealtime).subscribeToGroupState(groupId, changed),
  (event) {
    if (isStreamGroupStateEvent(event, groupId)) {
      changed();
    }
  },
  changed,
);
