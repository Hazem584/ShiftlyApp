import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import 'stream_chat_history.dart';

Future<({stream.Message? quote, Map<String, Object?> extra})> streamReply(
  ChatRepository legacy,
  StreamChatHistory history,
  String workspaceId,
  String groupId,
  String? replyToMessageId,
) async {
  stream.Message? quote;
  Map<String, Object?> extra = {};
  if (replyToMessageId != null) {
    quote = await history.find(workspaceId, groupId, replyToMessageId);
    if (quote == null) {
      final earlier = await legacy.reconcileMessages(workspaceId, groupId, [
        replyToMessageId,
      ]);
      if (earlier.isNotEmpty) {
        final item = earlier.first;
        extra = {
          'shiftly_reply_id': item.id,
          'shiftly_reply': {
            'id': item.id,
            'text': item.text,
            'type': item.type,
            'sender': {
              'membershipId': item.sender.membershipId,
              'fullName': item.sender.fullName,
            },
          },
        };
      }
    }
  }
  return (quote: quote, extra: extra);
}
