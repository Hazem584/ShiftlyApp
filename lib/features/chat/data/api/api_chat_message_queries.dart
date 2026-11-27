import 'package:shiftly/features/chat/data/api/api_chat_repository_base.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

mixin ApiChatMessageQueries on ApiChatRepositoryBase {
  @override
  Future<ChatMessagePage> searchMessages(
    String workspaceId,
    String groupId, {
    String? query,
    bool pinned = false,
    String? cursor,
  }) => request(() async {
    final res = await dio.get<Object?>(
      '${groupPath(workspaceId, groupId)}/search',
      queryParameters: {'q': ?query, 'pinned': pinned, 'cursor': ?cursor},
    );
    final json = chatMap(res.data);
    return ChatMessagePage(
      messages: chatList(json['data'])
          .map((row) => ChatMessage.fromJson(chatMap(row)))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
    );
  });

  @override
  Future<ChatMessagePage> listMessages(
    String workspaceId,
    String groupId, {
    String? cursor,
    int limit = 30,
  }) => request(() async {
    if (limit < 1 || limit > 100) {
      throw const FormatException('Invalid message page limit');
    }
    final res = await dio.get<Object?>(
      '${groupPath(workspaceId, groupId)}/messages',
      queryParameters: {'limit': limit, 'cursor': ?cursor},
    );
    return _parseMessagePage(chatMap(res.data, 'message page'));
  });

  ChatMessagePage _parseMessagePage(Map<String, Object?> body) {
    final next = body['nextCursor'];
    final hasMore = body['hasMore'];
    if (hasMore is! bool) {
      throw const FormatException('Invalid pagination state');
    }
    if (next != null && (next is! String || next.trim().isEmpty)) {
      throw const FormatException('Invalid pagination cursor');
    }
    if (hasMore != (next != null)) {
      throw const FormatException('Inconsistent pagination state');
    }
    return ChatMessagePage(
      messages: chatList(body['data'], 'messages')
          .map((e) => ChatMessage.fromJson(chatMap(e, 'message')))
          .toList(growable: false),
      nextCursor: next as String?,
    );
  }

  @override
  Future<List<ChatMessage>> reconcileMessages(
    String workspaceId,
    String groupId,
    List<String> ids,
  ) => request(() async {
    if (ids.isEmpty) return [];
    final res = await dio.post<Object?>(
      '${groupPath(workspaceId, groupId)}/messages/sync',
      data: {'ids': ids.take(500).toList()},
    );
    return (chatMap(res.data)['data'] as List)
        .map((m) => ChatMessage.fromJson(chatMap(m)))
        .toList();
  });
}
