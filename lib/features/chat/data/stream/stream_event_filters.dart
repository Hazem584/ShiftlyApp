import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

bool isStreamInboxEvent(stream.Event event) =>
    event.cid?.startsWith('shiftly:') == true ||
    event.type.startsWith('notification.');

bool isStreamGroupStateEvent(stream.Event event, String groupId) =>
    event.cid == 'shiftly:$groupId' &&
    event.message == null &&
    event.type != 'typing.start' &&
    event.type != 'typing.stop';
