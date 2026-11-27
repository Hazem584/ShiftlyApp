import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import '../../domain/entities/chat_inbox_activity.dart';
import '../../domain/repositories/chat_realtime.dart';
import 'stream_chat_connection.dart';
import 'stream_chat_mapper.dart';
import 'stream_event_filters.dart';
import 'stream_event_listener.dart';
import 'stream_event_subscription.dart';

ChatRealtimeSubscription subscribeStreamInbox(
  StreamChatConnection connection,
  ChatRealtimeSubscription legacy,
  void Function(ChatInboxActivity) onActivity,
  void Function() onResync,
) {
  final generation = connection.generation;
  final local = connection.inboxActivity.listen((activity) {
    if (generation == connection.generation) onActivity(activity);
  });
  final remote = listenStreamEvents(connection, legacy, (event) {
    final activity = _inboxMessage(event);
    if (activity != null) onActivity(activity);
    if (isStreamInboxEvent(event)) onResync();
  }, onResync);
  return StreamEventSubscription(() async {
    await local.cancel();
    await remote.cancel();
  });
}

ChatInboxMessage? _inboxMessage(stream.Event event) {
  final isNew =
      event.type == stream.EventType.messageNew ||
      event.type == stream.EventType.notificationMessageNew;
  if (!isNew && event.type != stream.EventType.messageUpdated) return null;
  final cid = event.cid ?? event.channel?.cid;
  final message = event.message;
  if (cid == null ||
      !cid.startsWith('shiftly:') ||
      message == null ||
      message.parentId != null ||
      message.shadowed ||
      message.isShadowed ||
      !StreamChatMapper.supported(message)) {
    return null;
  }
  return ChatInboxMessage(
    StreamChatMapper.message(message, cid.substring('shiftly:'.length)),
    isNew: isNew,
  );
}
