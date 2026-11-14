import 'dart:typed_data';

import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_session_repository.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import 'stream_chat_connection.dart';
import 'stream_chat_history.dart';
import 'stream_chat_mapper.dart';
import 'stream_chat_media.dart';
import 'stream_chat_request.dart';

class StreamChatRepository extends ChatRepository
    implements ChatSessionRepository {
  StreamChatRepository(this.legacy, this.connection)
    : media = StreamChatMedia(connection),
      history = StreamChatHistory(legacy, connection);
  final ChatRepository legacy;
  final StreamChatConnection connection;
  final StreamChatMedia media;
  final StreamChatHistory history;
  Future<List<ChatGroup>>? _listing;
  @override
  void bindChatSession(FeatureSessionScope? scope) {
    connection.bind(scope);
    media.reset();
    history.reset();
    _listing = null;
  }

  Future<bool> _enabled(String workspaceId) async =>
      await connection.clientFor(workspaceId) != null;
  @override
  Future<List<ChatGroup>> listGroups(String workspaceId) {
    final existing = _listing;
    if (existing != null) return existing;
    late final Future<List<ChatGroup>> request;
    request =
        streamChatRequest(() async {
          final base = await legacy.listGroups(workspaceId);
          if (!await _enabled(workspaceId)) return base;
          final channels = await connection.channels(
            workspaceId,
            base.map((g) => g.id).toSet(),
          );
          return [
            for (final group in base)
              if (channels[group.id] != null)
                StreamChatMapper.group(group, channels[group.id]!),
          ];
        }).whenComplete(() {
          if (identical(_listing, request)) _listing = null;
        });
    _listing = request;
    return request;
  }

  @override
  Future<ChatGroup> getGroup(String workspaceId, String groupId) =>
      streamChatRequest(() async {
        final base = await legacy.getGroup(workspaceId, groupId);
        if (!await _enabled(workspaceId)) return base;
        return StreamChatMapper.group(
          base,
          await connection.channel(workspaceId, groupId),
        );
      });
  @override
  Future<ChatGroup> createGroup(
    String workspaceId, {
    required String name,
    String? description,
    required List<String> memberMembershipIds,
  }) => legacy.createGroup(
    workspaceId,
    name: name,
    description: description,
    memberMembershipIds: memberMembershipIds,
  );
  @override
  Future<void> updateGroup(
    String workspaceId,
    String groupId, {
    required String name,
    String? description,
  }) => legacy.updateGroup(
    workspaceId,
    groupId,
    name: name,
    description: description,
  );
  @override
  Future<void> archiveGroup(String workspaceId, String groupId) =>
      legacy.archiveGroup(workspaceId, groupId);
  @override
  Future<void> addMembers(
    String workspaceId,
    String groupId,
    List<String> ids,
  ) => legacy.addMembers(workspaceId, groupId, ids);
  @override
  Future<void> removeMember(String workspaceId, String groupId, String id) =>
      legacy.removeMember(workspaceId, groupId, id);
  @override
  Future<ChatMessagePage> listMessages(
    String workspaceId,
    String groupId, {
    String? cursor,
    int limit = 30,
  }) =>
      history.listMessages(workspaceId, groupId, cursor: cursor, limit: limit);
  Future<ChatMessage> _send(
    String workspaceId,
    String groupId,
    stream.Message message,
  ) async {
    final channel = await connection.channel(workspaceId, groupId);
    try {
      final response = await channel.sendMessage(message, skipEnrichUrl: true);
      return StreamChatMapper.message(response.message, groupId);
    } on stream.StreamChatNetworkError catch (error) {
      if (error.statusCode == 409) {
        final existing = await history.find(workspaceId, groupId, message.id);
        if (existing != null) {
          return StreamChatMapper.message(existing, groupId);
        }
      }
      rethrow;
    }
  }

  @override
  Future<ChatMessage> sendMessage(
    String workspaceId,
    String groupId, {
    required String text,
    required String clientMessageId,
    String? replyToMessageId,
  }) => streamChatRequest(() async {
    if (!await _enabled(workspaceId)) {
      return legacy.sendMessage(
        workspaceId,
        groupId,
        text: text,
        clientMessageId: clientMessageId,
        replyToMessageId: replyToMessageId,
      );
    }
    stream.Message? quote;
    Map<String, Object?> extra = {};
    if (replyToMessageId != null) {
      quote = await history.find(workspaceId, groupId, replyToMessageId);
      if (quote == null) {
        final earlier = await legacy.reconcileMessages(workspaceId, groupId, [
          replyToMessageId,
        ]);
        if (earlier.isNotEmpty) {
          final item = earlier.first;
          extra = {
            'shiftly_reply_id': item.id,
            'shiftly_reply': {
              'id': item.id,
              'text': item.text,
              'type': item.type,
              'sender': {
                'membershipId': item.sender.membershipId,
                'fullName': item.sender.fullName,
              },
            },
          };
        }
      }
    }
    return _send(
      workspaceId,
      groupId,
      stream.Message(
        id: clientMessageId,
        text: text,
        quotedMessage: quote,
        extraData: extra,
      ),
    );
  });
  @override
  Future<ChatUploadAuthorization> initiateUpload(
    String workspaceId,
    String groupId, {
    required String type,
    required String mimeType,
    required int sizeBytes,
    int? durationMs,
    String? fileName,
  }) => streamChatRequest(() async {
    if (!await _enabled(workspaceId)) {
      return legacy.initiateUpload(
        workspaceId,
        groupId,
        type: type,
        mimeType: mimeType,
        sizeBytes: sizeBytes,
        durationMs: durationMs,
        fileName: fileName,
      );
    }
    await connection.channel(workspaceId, groupId);
    return media.prepare(
      workspaceId,
      groupId,
      type: type,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      durationMs: durationMs,
      fileName: fileName,
    );
  });
  @override
  Future<void> uploadSigned(
    ChatUploadAuthorization authorization,
    Uint8List bytes,
    String mimeType, {
    void Function(int, int)? onProgress,
    ChatUploadCancellation? cancellation,
  }) => streamChatRequest(() async {
    if (authorization.bucket != 'stream-chat') {
      return legacy.uploadSigned(
        authorization,
        bytes,
        mimeType,
        onProgress: onProgress,
        cancellation: cancellation,
      );
    }
    return media.upload(
      authorization,
      bytes,
      mimeType,
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
    String? caption,
  }) => streamChatRequest(() async {
    if (!await _enabled(workspaceId)) {
      return legacy.finalizeUpload(
        workspaceId,
        groupId,
        type: type,
        uploadId: uploadId,
        clientMessageId: clientMessageId,
        caption: caption,
      );
    }
    final result = await _send(
      workspaceId,
      groupId,
      stream.Message(
        id: clientMessageId,
        text: caption,
        attachments: [media.attachment(uploadId, workspaceId, groupId)],
      ),
    );
    media.complete(uploadId);
    return result;
  });
  @override
  Future<void> cancelUpload(
    String workspaceId,
    String groupId,
    String uploadId,
  ) => streamChatRequest(() async {
    if (!await _enabled(workspaceId)) {
      return legacy.cancelUpload(workspaceId, groupId, uploadId);
    }
    return media.cancel(workspaceId, groupId, uploadId);
  });
  @override
  Future<ChatMessage> sendLocation(
    String workspaceId,
    String groupId, {
    required ChatLocation location,
    required String clientMessageId,
  }) => streamChatRequest(() async {
    if (!await _enabled(workspaceId)) {
      return legacy.sendLocation(
        workspaceId,
        groupId,
        location: location,
        clientMessageId: clientMessageId,
      );
    }
    if (!location.isValid) throw const FormatException('Invalid location');
    return _send(
      workspaceId,
      groupId,
      stream.Message(
        id: clientMessageId,
        extraData: {'shiftly_location': location.toJson()},
      ),
    );
  });
  @override
  Future<ChatMediaUrl> mediaUrl(
    String workspaceId,
    String groupId,
    String messageId,
  ) => streamChatRequest(() async {
    if (!await _enabled(workspaceId)) {
      return legacy.mediaUrl(workspaceId, groupId, messageId);
    }
    final message = await history.find(workspaceId, groupId, messageId);
    if (message == null) {
      return legacy.mediaUrl(workspaceId, groupId, messageId);
    }
    final attachment = message.attachments.firstOrNull,
        uri = Uri.tryParse(attachment?.assetUrl ?? attachment?.imageUrl ?? '');
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const FormatException('Invalid chat attachment URL');
    }
    return ChatMediaUrl(
      url: uri,
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
    );
  });
  @override
  Future<ChatMessage> setReaction(
    String workspaceId,
    String groupId,
    String messageId, {
    required String? emoji,
  }) => streamChatRequest(() async {
    if (!await _enabled(workspaceId)) {
      return legacy.setReaction(workspaceId, groupId, messageId, emoji: emoji);
    }
    final message = await history.find(workspaceId, groupId, messageId);
    if (message == null) {
      return legacy.setReaction(workspaceId, groupId, messageId, emoji: emoji);
    }
    final channel = await connection.channel(workspaceId, groupId);
    if (emoji == null) {
      for (final reaction in message.ownReactions ?? <stream.Reaction>[]) {
        await channel.deleteReaction(message, reaction);
      }
    } else {
      if (!ChatReaction.choices.contains(emoji)) {
        throw const FormatException('Invalid reaction');
      }
      await channel.sendReaction(
        message,
        stream.Reaction(type: emoji),
        enforceUnique: true,
      );
    }
    return StreamChatMapper.message(
      (await history.find(workspaceId, groupId, messageId))!,
      groupId,
    );
  });
  @override
  Future<List<ChatMessage>> reconcileMessages(
    String workspaceId,
    String groupId,
    List<String> ids,
  ) => streamChatRequest(() async {
    if (!await _enabled(workspaceId)) {
      return legacy.reconcileMessages(workspaceId, groupId, ids);
    }
    final channel = await connection.channel(workspaceId, groupId);
    final response = await channel.getMessagesById(ids);
    final current = response.messages
        .where(StreamChatMapper.supported)
        .map((m) => StreamChatMapper.message(m, groupId))
        .toList();
    final missing = ids.where((id) => !current.any((m) => m.id == id)).toList();
    return [
      ...current,
      if (missing.isNotEmpty)
        ...await legacy.reconcileMessages(workspaceId, groupId, missing),
    ];
  });
  @override
  Future<void> markRead(String workspaceId, String groupId, String id) =>
      streamChatRequest(() async {
        if (!await _enabled(workspaceId)) {
          return legacy.markRead(workspaceId, groupId, id);
        }
        final current = await history.find(workspaceId, groupId, id);
        if (current == null) return legacy.markRead(workspaceId, groupId, id);
        await (await connection.channel(
          workspaceId,
          groupId,
        )).markRead(messageId: id);
        await history.markEarlierRead(workspaceId, groupId);
      });
  @override
  Future<int> unreadCount(String workspaceId) => streamChatRequest(() async {
    if (!await _enabled(workspaceId)) return legacy.unreadCount(workspaceId);
    final groups = await listGroups(workspaceId);
    return groups.fold<int>(0, (sum, g) => sum + g.unreadCount);
  });
  @override
  Future<ChatMessagePage> searchMessages(
    String workspaceId,
    String groupId, {
    String? query,
    bool pinned = false,
    String? cursor,
  }) => history.searchMessages(
    workspaceId,
    groupId,
    query: query,
    pinned: pinned,
    cursor: cursor,
  );
  @override
  Future<ChatMessage> pinMessage(
    String workspaceId,
    String groupId,
    String messageId, {
    required bool pinned,
  }) => streamChatRequest(() async {
    if (!await _enabled(workspaceId)) {
      return legacy.pinMessage(workspaceId, groupId, messageId, pinned: pinned);
    }
    final message = await history.find(workspaceId, groupId, messageId);
    if (message == null) {
      return legacy.pinMessage(workspaceId, groupId, messageId, pinned: pinned);
    }
    final channel = await connection.channel(workspaceId, groupId);
    final result = pinned
        ? await channel.pinMessage(message)
        : await channel.unpinMessage(message);
    return StreamChatMapper.message(result.message, groupId);
  });
}
