import 'package:shiftly/features/chat/data/api/api_chat_repository_base.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

mixin ApiChatUploadCompletion on ApiChatRepositoryBase {
  @override
  Future<ChatMessage> finalizeUpload(
    String workspaceId,
    String groupId, {
    required String type,
    required String uploadId,
    required String clientMessageId,
    String? caption,
  }) => request(() async {
    if (!const ['IMAGE', 'VOICE', 'DOCUMENT'].contains(type) ||
        chatOptionalUuid(uploadId) == null ||
        chatOptionalUuid(clientMessageId) == null) {
      throw const FormatException('Invalid media finalization');
    }
    final res = await dio.post<Object?>(
      '${groupPath(workspaceId, groupId)}/messages',
      data: {
        'type': type,
        'uploadId': uploadId,
        'clientMessageId': clientMessageId,
        if (caption?.trim().isNotEmpty == true) 'caption': caption!.trim(),
      },
    );
    return ChatMessage.fromJson(chatMap(res.data, 'message'));
  });

  @override
  Future<void> cancelUpload(
    String workspaceId,
    String groupId,
    String uploadId,
  ) => request(() async {
    final res = await dio.delete<Object?>(
      '${groupPath(workspaceId, groupId)}/uploads/$uploadId',
    );
    final body = chatMap(res.data, 'upload cancellation');
    if (body['cancelled'] != true) {
      throw const FormatException('Invalid upload cancellation');
    }
  });

  @override
  Future<ChatMediaUrl> mediaUrl(
    String workspaceId,
    String groupId,
    String messageId,
  ) => request(() async {
    final res = await dio.get<Object?>(
      '${groupPath(workspaceId, groupId)}/messages/$messageId/media-url',
    );
    final body = chatMap(res.data, 'media URL');
    final rawUrl = body['url'];
    final rawExpires = body['expiresAt'];
    final url = rawUrl is String ? Uri.tryParse(rawUrl) : null;
    final expires = rawExpires is String ? DateTime.tryParse(rawExpires) : null;
    if (url == null ||
        !url.isAbsolute ||
        url.scheme != 'https' ||
        expires == null) {
      throw const FormatException('Invalid media URL');
    }
    return ChatMediaUrl(url: url, expiresAt: expires.toUtc());
  });
}
