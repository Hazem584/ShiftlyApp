import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

final streamUuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);
bool isSupportedStreamMessage(stream.Message message) =>
    streamUuid.hasMatch(message.id) &&
    streamUuid.hasMatch(message.user?.id ?? '');
