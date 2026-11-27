import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

bool isStreamInboxEvent(stream.Event event) {
  final cid = event.cid ?? event.channel?.cid;
  if (cid != null && !cid.startsWith('shiftly:')) return false;
  final type = event.type;
  return type.startsWith('notification.') ||
      (cid != null &&
          (type == stream.EventType.messageNew ||
              type == stream.EventType.messageUpdated ||
              type == stream.EventType.messageDeleted ||
              type == stream.EventType.messageRead ||
              type.startsWith('channel.') ||
              type.startsWith('member.')));
}

bool isStreamGroupStateEvent(stream.Event event, String groupId) =>
    (event.cid ?? event.channel?.cid) == 'shiftly:$groupId' &&
    event.message == null &&
    event.type != 'typing.start' &&
    event.type != 'typing.stop';
