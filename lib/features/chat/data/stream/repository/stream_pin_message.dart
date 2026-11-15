import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

import '../stream_chat_mapper.dart';
import '../stream_chat_repository_base.dart';
import '../stream_chat_request.dart';

mixin StreamPinMessage on StreamChatRepositoryBase {
  @override
  Future<ChatMessage> pinMessage(
    String workspaceId,
    String groupId,
    String messageId, {
    required bool pinned,
  }) => streamChatRequest(() async {
    if (!await streamEnabled(workspaceId)) {
      return legacy.pinMessage(workspaceId, groupId, messageId, pinned: pinned);
    }
    final message = await history.find(workspaceId, groupId, messageId);
    if (message == null) {
      return legacy.pinMessage(workspaceId, groupId, messageId, pinned: pinned);
    }
    final channel = await connection.channel(workspaceId, groupId);
    final result = pinned
        ? await channel.pinMessage(message)
        : await channel.unpinMessage(message);
    return StreamChatMapper.message(result.message, groupId);
  });
}
