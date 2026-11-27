import 'package:shiftly/features/chat/data/api/api_chat_repository_base.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

mixin ApiChatMessageActions on ApiChatRepositoryBase {
  @override
  Future<ChatMessage> sendMessage(
    String workspaceId,
    String groupId, {
    required String text,
    required String clientMessageId,
    String? replyToMessageId,
  }) => request(() async {
    final res = await dio.post<Object?>(
      '${groupPath(workspaceId, groupId)}/messages',
      data: {
        'type': 'TEXT',
        'text': validatedMessageText(text),
        'clientMessageId': clientMessageId,
        'replyToMessageId': ?replyToMessageId,
      },
    );
    return ChatMessage.fromJson(chatMap(res.data, 'message'));
  });

  @override
  Future<ChatMessage> sendLocation(
    String workspaceId,
    String groupId, {
    required ChatLocation location,
    required String clientMessageId,
  }) => request(() async {
    if (!location.isValid) throw const FormatException('Invalid location');
    final res = await dio.post<Object?>(
      '${groupPath(workspaceId, groupId)}/messages',
      data: {
        'type': 'LOCATION',
        'clientMessageId': clientMessageId,
        'location': location.toJson(),
      },
    );
    return ChatMessage.fromJson(chatMap(res.data, 'message'));
  });

  @override
  Future<ChatMessage> pinMessage(
    String workspaceId,
    String groupId,
    String messageId, {
    required bool pinned,
  }) => request(() async {
    final path = '${groupPath(workspaceId, groupId)}/messages/$messageId/pin';
    final res = await dio.patch<Object?>(path, data: {'pinned': pinned});
    return ChatMessage.fromJson(chatMap(res.data));
  });

  @override
  Future<ChatMessage> setReaction(
    String workspaceId,
    String groupId,
    String messageId, {
    required String? emoji,
  }) => request(() async {
    final path =
        '${groupPath(workspaceId, groupId)}/messages/$messageId/reaction';
    final res = await dio.put<Object?>(path, data: {'emoji': emoji});
    return ChatMessage.fromJson(chatMap(res.data));
  });
}
