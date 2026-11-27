import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import 'stream_chat_mapper.dart';

void dispatchStreamMessage(
  stream.Event event,
  String groupId,
  void Function(ChatMessage) message,
  void Function() resync,
) {
  if ((event.cid ?? event.channel?.cid) != 'shiftly:$groupId') {
    return;
  }
  final value = event.message;
  if (value != null && StreamChatMapper.supported(value)) {
    message(StreamChatMapper.message(value, groupId));
  } else if (event.type != 'typing.start' && event.type != 'typing.stop') {
    resync();
  }
}
