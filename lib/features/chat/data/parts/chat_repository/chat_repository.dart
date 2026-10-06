part of '../../chat_repository.dart';

abstract class ChatRepository {
  const ChatRepository();

  Future<List<ChatGroup>> listGroups(String workspaceId);
  Future<ChatGroup> getGroup(String workspaceId, String groupId);
  Future<ChatGroup> createGroup(
    String workspaceId, {
    required String name,
    String? description,
    required List<String> memberMembershipIds,
  });
  Future<void> updateGroup(
    String workspaceId,
    String groupId, {
    required String name,
    String? description,
  });
  Future<void> archiveGroup(String workspaceId, String groupId);
  Future<void> addMembers(
    String workspaceId,
    String groupId,
    List<String> membershipIds,
  );
  Future<void> removeMember(
    String workspaceId,
    String groupId,
    String membershipId,
  );
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
  Future<ChatUploadAuthorization> initiateUpload(
    String workspaceId,
    String groupId, {
    required String type,
    required String mimeType,
    required int sizeBytes,
    int? durationMs,
  }) => throw UnsupportedError('Chat media is unavailable');
  Future<void> uploadSigned(
    ChatUploadAuthorization authorization,
    Uint8List bytes,
    String mimeType, {
    void Function(int sent, int total)? onProgress,
    ChatUploadCancellation? cancellation,
  }) => throw UnsupportedError('Chat media is unavailable');
  Future<ChatMessage> finalizeUpload(
    String workspaceId,
    String groupId, {
    required String type,
    required String uploadId,
    required String clientMessageId,
  }) => throw UnsupportedError('Chat media is unavailable');
  Future<void> cancelUpload(
    String workspaceId,
    String groupId,
    String uploadId,
  ) => throw UnsupportedError('Chat media is unavailable');
  Future<ChatMessage> sendLocation(
    String workspaceId,
    String groupId, {
    required ChatLocation location,
    required String clientMessageId,
  }) => throw UnsupportedError('Location messages are unavailable');
  Future<ChatMediaUrl> mediaUrl(
    String workspaceId,
    String groupId,
    String messageId,
  ) => throw UnsupportedError('Chat media is unavailable');
  Future<void> markRead(String workspaceId, String groupId, String messageId);
  Future<int> unreadCount(String workspaceId);
}
