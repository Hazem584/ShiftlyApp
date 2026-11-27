import '../../../domain/entities/chat_inbox_activity.dart';
import '../stream_chat_repository_base.dart';
import '../stream_chat_request.dart';

mixin StreamMarkRead on StreamChatRepositoryBase {
  @override
  Future<void> markRead(String workspaceId, String groupId, String messageId) =>
      streamChatRequest(() async {
        final generation = connection.generation;
        if (await streamEnabled(workspaceId)) {
          final channel = await connection.channel(workspaceId, groupId);
          final cached = channel.state?.messages.any((m) => m.id == messageId);
          if (cached == true ||
              await history.find(workspaceId, groupId, messageId) != null) {
            await channel.markRead(messageId: messageId);
            await history.legacyReads.markEarlierRead(workspaceId, groupId);
            connection.publishInboxActivity(
              generation,
              ChatInboxRead(groupId, messageId),
            );
            return;
          }
        }
        await legacy.markRead(workspaceId, groupId, messageId);
        connection.publishInboxActivity(
          generation,
          ChatInboxRead(groupId, messageId),
        );
      });
}
