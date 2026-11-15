import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

import 'chat_group_repository.dart';
import 'chat_media_repository.dart';

export 'package:shiftly/features/chat/domain/entities/chat_upload_cancellation.dart';

abstract class ChatRepository with ChatMediaRepository, ChatGroupRepository {
  const ChatRepository();

  Future<ChatMessagePage> listMessages(
    String workspaceId,
    String groupId, {
    String? cursor,
    int limit = 30,
  });
  Future<ChatMessage> sendMessage(
    String workspaceId,
    String groupId, {
    required String text,
    required String clientMessageId,
    String? replyToMessageId,
  });
  Future<ChatMessage> setReaction(
    String workspaceId,
    String groupId,
    String messageId, {
    required String? emoji,
  }) => throw UnsupportedError('Reactions unavailable');
  Future<List<ChatMessage>> reconcileMessages(
    String workspaceId,
    String groupId,
    List<String> ids,
  ) async => [];
  Future<void> markRead(String workspaceId, String groupId, String messageId);
  Future<int> unreadCount(String workspaceId);
  Future<ChatMessagePage> searchMessages(
    String workspaceId,
    String groupId, {
    String? query,
    bool pinned = false,
    String? cursor,
  }) => throw UnsupportedError('Chat search is unavailable');
  Future<ChatMessage> pinMessage(
    String workspaceId,
    String groupId,
    String messageId, {
    required bool pinned,
  }) => throw UnsupportedError('Message pinning is unavailable');
}
