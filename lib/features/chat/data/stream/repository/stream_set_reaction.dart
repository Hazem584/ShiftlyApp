import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import '../stream_chat_mapper.dart';
import '../stream_chat_repository_base.dart';
import '../stream_chat_request.dart';

mixin StreamSetReaction on StreamChatRepositoryBase {
  @override
  Future<ChatMessage> setReaction(
    String workspaceId,
    String groupId,
    String messageId, {
    required String? emoji,
  }) => streamChatRequest(() async {
    if (!await streamEnabled(workspaceId)) {
      return legacy.setReaction(workspaceId, groupId, messageId, emoji: emoji);
    }
    final message = await history.find(workspaceId, groupId, messageId);
    if (message == null) {
      return legacy.setReaction(workspaceId, groupId, messageId, emoji: emoji);
    }
    final channel = await connection.channel(workspaceId, groupId);
    if (emoji == null) {
      for (final reaction in message.ownReactions ?? <stream.Reaction>[]) {
        await channel.deleteReaction(message, reaction);
      }
    } else {
      if (!ChatReaction.choices.contains(emoji)) {
        throw const FormatException('Invalid reaction');
      }
      await channel.sendReaction(
        message,
        stream.Reaction(type: emoji),
        enforceUnique: true,
      );
    }
    return StreamChatMapper.message(
      (await history.find(workspaceId, groupId, messageId))!,
      groupId,
    );
  });
}
