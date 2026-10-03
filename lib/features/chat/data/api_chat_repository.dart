import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/features/chat/data/chat_models.dart';
import 'package:shiftly/features/chat/data/chat_repository.dart';
import 'package:shiftly/features/chat/data/signed_chat_upload_client.dart';

class ApiChatRepository extends ChatRepository {
  ApiChatRepository(
    this._dio, {
    required ChatStorageUploader storageUploader,
  }) : _signedUploader = SignedChatUploadClient(storageUploader);
  final Dio _dio;
  final SignedChatUploadClient _signedUploader;

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
  Future<ChatUploadAuthorization> initiateUpload(
    String workspaceId,
    String groupId, {
    required String type,
    required String mimeType,
    required int sizeBytes,
    int? durationMs,
  }) => _request(() async {
    if (!const ['IMAGE', 'VOICE'].contains(type) || sizeBytes < 1) {
      throw const FormatException('Invalid upload metadata');
    }
    if ((type == 'IMAGE' && durationMs != null) ||
        (type == 'VOICE' && (durationMs == null || durationMs < 1))) {
      throw const FormatException('Invalid upload metadata');
    }
    final response = await _dio.post<Object?>(
      '${_group(workspaceId, groupId)}/uploads',
      data: {
        'type': type,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
        'durationMs': ?durationMs,
      },
    );
    return ChatUploadAuthorization.fromJson(
      chatMap(response.data, 'upload authorization'),
    ).withExpectedUpload(mimeType: mimeType, sizeBytes: sizeBytes);
  });

  @override
  Future<void> uploadSigned(
    ChatUploadAuthorization authorization,
    Uint8List bytes,
    String mimeType, {
    void Function(int sent, int total)? onProgress,
    ChatUploadCancellation? cancellation,
  }) => _request(() async {
    if (DateTime.now().toUtc().isAfter(authorization.expiresAt)) {
      throw const FormatException('Upload authorization expired');
    }
    if (authorization.expectedMimeType != mimeType ||
        authorization.expectedSizeBytes != bytes.length) {
      throw const FormatException('Upload metadata changed after initiation');
    }
    await _signedUploader.upload(
      authorization: authorization,
      bytes: bytes,
      mimeType: mimeType,
      onProgress: onProgress,
      cancellation: cancellation,
    );
  });

  @override
  Future<ChatMessage> finalizeUpload(
    String workspaceId,
    String groupId, {
    required String type,
    required String uploadId,
    required String clientMessageId,
  }) => _request(() async {
    if (!const ['IMAGE', 'VOICE'].contains(type) ||
        chatOptionalUuid(uploadId) == null ||
        chatOptionalUuid(clientMessageId) == null) {
      throw const FormatException('Invalid media finalization');
    }
    return ChatMessage.fromJson(
      chatMap(
        (await _dio.post<Object?>(
          '${_group(workspaceId, groupId)}/messages',
          data: {
            'type': type,
            'uploadId': uploadId,
            'clientMessageId': clientMessageId,
          },
        )).data,
        'message',
      ),
    );
  });

  @override
  Future<void> cancelUpload(
    String workspaceId,
    String groupId,
    String uploadId,
  ) => _request(() async {
    final body = chatMap(
      (await _dio.delete<Object?>(
        '${_group(workspaceId, groupId)}/uploads/$uploadId',
      )).data,
      'upload cancellation',
    );
    if (body['cancelled'] != true) {
      throw const FormatException('Invalid upload cancellation');
    }
  });

  @override
  Future<ChatMessage> sendLocation(
    String workspaceId,
    String groupId, {
    required ChatLocation location,
    required String clientMessageId,
  }) => _request(() async {
    if (!location.isValid) throw const FormatException('Invalid location');
    return ChatMessage.fromJson(
      chatMap(
        (await _dio.post<Object?>(
          '${_group(workspaceId, groupId)}/messages',
          data: {
            'type': 'LOCATION',
            'clientMessageId': clientMessageId,
            'location': location.toJson(),
          },
        )).data,
        'message',
      ),
    );
  });

  @override
  Future<ChatMediaUrl> mediaUrl(
    String workspaceId,
    String groupId,
    String messageId,
  ) => _request(() async {
    final body = chatMap(
      (await _dio.get<Object?>(
        '${_group(workspaceId, groupId)}/messages/$messageId/media-url',
      )).data,
      'media URL',
    );
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
