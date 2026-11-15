import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import '../stream_chat_repository_base.dart';
import '../stream_chat_request.dart';
import '../stream_reply.dart';

mixin StreamSendMessage on StreamChatRepositoryBase {
  @override
  Future<ChatMessage> sendMessage(
    String workspaceId,
    String groupId, {
    required String text,
    required String clientMessageId,
    String? replyToMessageId,
  }) => streamChatRequest(() async {
    if (!await streamEnabled(workspaceId)) {
      return legacy.sendMessage(
        workspaceId,
        groupId,
        text: text,
        clientMessageId: clientMessageId,
        replyToMessageId: replyToMessageId,
      );
    }
    final reply = await streamReply(
      legacy,
      history,
      workspaceId,
      groupId,
      replyToMessageId,
    );
    return sendStreamMessage(
      workspaceId,
      groupId,
      stream.Message(
        id: clientMessageId,
        text: text,
        quotedMessage: reply.quote,
        extraData: reply.extra,
      ),
    );
  });
}
