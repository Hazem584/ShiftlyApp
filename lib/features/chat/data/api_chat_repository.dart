import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_exception.dart';
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
    final body = chatMap(
      (await _dio.get<Object?>(_groups(workspaceId))).data,
      'chat groups response',
    );
    return chatList(body['data'], 'chat groups')
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
  }) => _request(() async {
    final trimmedName = name.trim();
    final trimmedDescription = description?.trim();
    _validateGroupFields(trimmedName, trimmedDescription);
    final ids = _uniqueUuids(memberMembershipIds, 'memberMembershipIds');
    return _parseGroup(
      (await _dio.post<Object?>(
        _groups(workspaceId),
        data: {
          'name': trimmedName,
          if (trimmedDescription?.isNotEmpty == true)
            'description': trimmedDescription,
          'memberMembershipIds': ids,
        },
      )).data,
    );
  });

  @override
  Future<void> updateGroup(
    String workspaceId,
    String groupId, {
    required String name,
    String? description,
  }) => _request(() async {
    final trimmedName = name.trim();
    final trimmedDescription = description?.trim();
    _validateGroupFields(trimmedName, trimmedDescription);
    await _dio.patch<Object?>(
      _group(workspaceId, groupId),
      data: {
        'name': trimmedName,
        'description': trimmedDescription?.isEmpty == true
            ? null
            : trimmedDescription,
      },
    );
  });

  @override
  Future<void> archiveGroup(String workspaceId, String groupId) => _request(
    () async => _dio.patch<Object?>('${_group(workspaceId, groupId)}/archive'),
  );

  @override
  Future<void> addMembers(
    String workspaceId,
    String groupId,
    List<String> membershipIds,
  ) => _request(() async {
    final body = chatMap(
      (await _dio.post<Object?>(
        '${_group(workspaceId, groupId)}/members',
        data: {'membershipIds': _uniqueUuids(membershipIds, 'membershipIds')},
      )).data,
      'add members acknowledgement',
    );
    final count = body['addedCount'];
    if (count is! int || count < 0) {
      throw const FormatException('Invalid add members acknowledgement');
    }
  });

  @override
  Future<void> removeMember(
    String workspaceId,
    String groupId,
    String membershipId,
  ) => _request(() async {
    final body = chatMap(
      (await _dio.delete<Object?>(
        '${_group(workspaceId, groupId)}/members/$membershipId',
      )).data,
      'remove member acknowledgement',
    );
    if (body['removed'] != true) {
      throw const FormatException('Invalid remove member acknowledgement');
    }
  });

  @override
  Future<ChatMessagePage> listMessages(
    String workspaceId,
    String groupId, {
    String? cursor,
    int limit = 30,
  }) => _request(() async {
    if (limit < 1 || limit > 100) {
      throw const FormatException('Invalid message page limit');
    }
    final body = chatMap(
      (await _dio.get<Object?>(
        '${_group(workspaceId, groupId)}/messages',
        queryParameters: {'limit': limit, 'cursor': ?cursor},
      )).data,
      'message page',
    );
    final raw = body['data'];
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
            'text': _validatedMessageText(text),
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
    final value = body['count'];
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
        error is DioException && error.error is ApiException
            ? error.error! as ApiException
            : error,
      );
    }
  }

  ChatGroup _parseGroup(Object? value) {
    return ChatGroup.fromJson(chatMap(value, 'chat group'));
  }

  List<String> _uniqueUuids(List<String> values, String label) {
    if (values.length > 500) throw FormatException('Invalid $label');
    final unique = <String>{};
    for (final value in values) {
      try {
        final id = chatOptionalUuid(value);
        if (id == null) throw const FormatException('Invalid UUID');
        unique.add(id);
      } on FormatException {
        throw FormatException('Invalid $label');
      }
    }
    return unique.toList(growable: false);
  }

  void _validateGroupFields(String name, String? description) {
    if (name.isEmpty || name.length > 80) {
      throw const FormatException('Invalid group name');
    }
    if (description != null && description.length > 500) {
      throw const FormatException('Invalid group description');
    }
  }

  String _validatedMessageText(String value) {
    final text = value.trim();
    if (text.isEmpty || text.length > 4000) {
      throw const FormatException('Invalid message text');
    }
    return text;
  }
}
