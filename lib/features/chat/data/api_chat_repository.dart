import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/features/chat/data/chat_models.dart';
import 'package:shiftly/features/chat/data/chat_repository.dart';

class ApiChatRepository implements ChatRepository {
  ApiChatRepository(this._dio);
  final Dio _dio;

  String _groups(String workspaceId) => '/workspaces/$workspaceId/chat/groups';
  String _group(String workspaceId, String groupId) =>
      '${_groups(workspaceId)}/$groupId';

  @override
  Future<List<ChatGroup>> listGroups(String workspaceId) => _request(() async {
    final body = (await _dio.get<Object?>(_groups(workspaceId))).data;
    final raw = body is Map ? (body['data'] ?? body['groups'] ?? body) : body;
    return chatList(raw, 'chat groups')
        .map((e) => ChatGroup.fromJson(chatMap(e, 'chat group')))
        .toList(growable: false);
  });

  @override
  Future<ChatGroup> getGroup(String workspaceId, String groupId) => _request(
    () async => _parseGroup(
      (await _dio.get<Object?>(_group(workspaceId, groupId))).data,
    ),
  );

  @override
  Future<ChatGroup> createGroup(
    String workspaceId, {
    required String name,
    String? description,
    required List<String> memberMembershipIds,
  }) => _request(
    () async => _parseGroup(
      (await _dio.post<Object?>(
        _groups(workspaceId),
        data: {
          'name': name.trim(),
          'description': description?.trim(),
          'memberMembershipIds': memberMembershipIds,
        },
      )).data,
    ),
  );

  @override
  Future<ChatGroup> updateGroup(
    String workspaceId,
    String groupId, {
    required String name,
    String? description,
  }) => _request(
    () async => _parseGroup(
      (await _dio.patch<Object?>(
        _group(workspaceId, groupId),
        data: {'name': name.trim(), 'description': description?.trim()},
      )).data,
    ),
  );

  @override
  Future<ChatGroup> archiveGroup(String workspaceId, String groupId) =>
      _request(
        () async => _parseGroup(
          (await _dio.patch<Object?>('${_group(workspaceId, groupId)}/archive'))
              .data,
        ),
      );

  @override
  Future<ChatGroup> addMembers(
    String workspaceId,
    String groupId,
    List<String> membershipIds,
  ) => _request(
    () async => _parseGroup(
      (await _dio.post<Object?>(
        '${_group(workspaceId, groupId)}/members',
        data: {'membershipIds': membershipIds},
      )).data,
    ),
  );

  @override
  Future<void> removeMember(
    String workspaceId,
    String groupId,
    String membershipId,
  ) => _request(() async {
    await _dio.delete<Object?>(
      '${_group(workspaceId, groupId)}/members/$membershipId',
    );
  });

  @override
  Future<ChatMessagePage> listMessages(
    String workspaceId,
    String groupId, {
    String? cursor,
    int limit = 30,
  }) => _request(() async {
    final body = chatMap(
      (await _dio.get<Object?>(
        '${_group(workspaceId, groupId)}/messages',
        queryParameters: {'limit': limit, 'cursor': ?cursor},
      )).data,
      'message page',
    );
    final raw = body['data'] ?? body['messages'];
    final pagination = body['pagination'];
    final next =
        body['nextCursor'] ??
        (pagination is Map ? pagination['nextCursor'] : null);
    if (next != null && (next is! String || next.trim().isEmpty)) {
      throw const FormatException('Invalid pagination cursor');
    }
    return ChatMessagePage(
      messages: chatList(raw, 'messages')
          .map((e) => ChatMessage.fromJson(chatMap(e, 'message')))
          .toList(growable: false),
      nextCursor: next as String?,
    );
  });

  @override
  Future<ChatMessage> sendMessage(
    String workspaceId,
    String groupId, {
    required String text,
    required String clientMessageId,
    String? replyToMessageId,
  }) => _request(
    () async => ChatMessage.fromJson(
      chatMap(
        (await _dio.post<Object?>(
          '${_group(workspaceId, groupId)}/messages',
          data: {
            'type': 'TEXT',
            'text': text.trim(),
            'clientMessageId': clientMessageId,
            'replyToMessageId': ?replyToMessageId,
          },
        )).data,
        'message',
      ),
    ),
  );

  @override
  Future<void> markRead(String workspaceId, String groupId, String messageId) =>
      _request(() async {
        await _dio.patch<Object?>(
          '${_group(workspaceId, groupId)}/read',
          data: {'messageId': messageId},
        );
      });

  @override
  Future<int> unreadCount(String workspaceId) => _request(() async {
    final body = chatMap(
      (await _dio.get<Object?>('/workspaces/$workspaceId/chat/unread-count'))
          .data,
      'unread count',
    );
    final value = body['count'] ?? body['unreadCount'];
    if (value is! int || value < 0) {
      throw const FormatException('Invalid unread count');
    }
    return value;
  });

  Future<T> _request<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error) {
      throw ApiErrorParser.parse(
        error is DioException && error.error != null ? error.error! : error,
      );
    }
  }

  ChatGroup _parseGroup(Object? value) {
    final body = chatMap(value, 'chat group');
    return ChatGroup.fromJson(
      chatMap(body['data'] ?? body['group'] ?? body, 'chat group'),
    );
  }
}
