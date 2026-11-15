import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import 'stream_group_mapper.dart';
import 'stream_message_identity.dart';
import 'stream_message_mapper.dart';

abstract final class StreamChatMapper {
  static bool supported(stream.Message message) =>
      isSupportedStreamMessage(message);
  static ChatMessage message(stream.Message source, String groupId) =>
      mapStreamMessage(source, groupId);
  static ChatGroup group(
    ChatGroup base,
    stream.Channel channel, {
    int? streamUnreadCount,
  }) => mapStreamGroup(base, channel, streamUnreadCount: streamUnreadCount);
}
