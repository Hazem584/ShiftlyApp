import '../stream_chat_repository_base.dart';
import '../stream_chat_request.dart';

mixin StreamMarkRead on StreamChatRepositoryBase {
  @override
  Future<void> markRead(String workspaceId, String groupId, String messageId) =>
      streamChatRequest(() async {
        if (!await streamEnabled(workspaceId)) {
          return legacy.markRead(workspaceId, groupId, messageId);
        }
        final current = await history.find(workspaceId, groupId, messageId);
        if (current == null) {
          return legacy.markRead(workspaceId, groupId, messageId);
        }
        await (await connection.channel(
          workspaceId,
          groupId,
        )).markRead(messageId: messageId);
        await history.markEarlierRead(workspaceId, groupId);
      });
}
