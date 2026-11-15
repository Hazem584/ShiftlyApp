import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

Map<String, Object?>? mapStreamReplyPreview(stream.Message source) {
  final quoted = source.quotedMessage;
  final data = source.extraData;
  return quoted == null
      ? (data['shiftly_reply'] as Map?)?.cast<String, Object?>()
      : {
          'id': quoted.id,
          'text': quoted.text,
          'type': 'TEXT',
          'sender': {
            'membershipId': quoted.user?.id,
            'fullName': quoted.user?.name,
          },
        };
}
