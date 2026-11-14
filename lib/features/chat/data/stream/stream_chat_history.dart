import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import 'stream_chat_connection.dart';
import 'stream_chat_mapper.dart';
import 'stream_chat_request.dart';

class StreamChatHistory {
  StreamChatHistory(this.legacy, this.connection);
  final ChatRepository legacy;
  final StreamChatConnection connection;
  final _earlierRead = <String, Future<void>>{};
  void reset() => _earlierRead.clear();
  Future<void> markEarlierRead(
    String workspaceId,
    String groupId,
  ) => _earlierRead
      .putIfAbsent('$workspaceId:$groupId', () async {
        final scope = connection.scope;
        final page = await legacy.listMessages(workspaceId, groupId, limit: 1);
        if (scope != connection.scope) return;
        if (page.messages.isNotEmpty) {
          await legacy.markRead(workspaceId, groupId, page.messages.first.id);
        }
      })
      .catchError((Object error) {
        _earlierRead.remove('$workspaceId:$groupId');
        throw error;
      });
  Future<bool> _enabled(String workspaceId) async =>
      await connection.clientFor(workspaceId) != null;
  Future<ChatMessagePage> listMessages(
    String workspaceId,
    String groupId, {
    String? cursor,
    int limit = 30,
  }) => streamChatRequest(() async {
    if (!await _enabled(workspaceId)) {
      return legacy.listMessages(
        workspaceId,
        groupId,
        cursor: cursor,
        limit: limit,
      );
    }
    if (cursor?.startsWith('legacy:') == true) {
      final page = await legacy.listMessages(
        workspaceId,
        groupId,
        cursor: cursor!.substring(7).isEmpty ? null : cursor.substring(7),
        limit: limit,
      );
      return ChatMessagePage(
        messages: page.messages,
        nextCursor: page.nextCursor == null
            ? null
            : 'legacy:${page.nextCursor}',
      );
    }
    final channel = await connection.channel(workspaceId, groupId);
    final state = await channel.query(
      messagesPagination: stream.PaginationParams(
        limit: limit,
        lessThan: cursor?.startsWith('stream:') == true
            ? cursor!.substring(7)
            : null,
      ),
    );
    final raw = state.messages ?? <stream.Message>[];
    final list = raw.where(StreamChatMapper.supported).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (raw.isEmpty) {
      final page = await legacy.listMessages(
        workspaceId,
        groupId,
        limit: limit,
      );
      return ChatMessagePage(
        messages: page.messages,
        nextCursor: page.nextCursor == null
            ? null
            : 'legacy:${page.nextCursor}',
      );
    }
    return ChatMessagePage(
      messages: list.map((m) => StreamChatMapper.message(m, groupId)).toList(),
      nextCursor: raw.length < limit
          ? 'legacy:'
          : 'stream:${(List<stream.Message>.of(raw)..sort((a, b) => a.createdAt.compareTo(b.createdAt))).first.id}',
    );
  });
  Future<stream.Message?> find(
    String workspaceId,
    String groupId,
    String id,
  ) async {
    final channel = await connection.channel(workspaceId, groupId);
    try {
      final response = await channel.getMessagesById([id]);
      return response.messages.where((m) => m.id == id).firstOrNull;
    } on stream.StreamChatNetworkError catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<ChatMessagePage> searchMessages(
    String workspaceId,
    String groupId, {
    String? query,
    bool pinned = false,
    String? cursor,
  }) => streamChatRequest(() async {
    if (!await _enabled(workspaceId)) {
      return legacy.searchMessages(
        workspaceId,
        groupId,
        query: query,
        pinned: pinned,
        cursor: cursor,
      );
    }
    if (cursor?.startsWith('legacy:') == true) {
      final page = await legacy.searchMessages(
        workspaceId,
        groupId,
        query: query,
        pinned: pinned,
        cursor: cursor!.substring(7).isEmpty ? null : cursor.substring(7),
      );
      return ChatMessagePage(
        messages: page.messages,
        nextCursor: page.nextCursor == null
            ? null
            : 'legacy:${page.nextCursor}',
      );
    }
    final channel = await connection.channel(workspaceId, groupId);
    final result = await channel.search(
      query: query?.isEmpty == true ? null : query,
      messageFilters: pinned ? stream.Filter.equal('pinned', true) : null,
      paginationParams: stream.PaginationParams(limit: 30, next: cursor),
    );
    final messages = result.results
        .map((r) => r.message)
        .where(StreamChatMapper.supported)
        .map((m) => StreamChatMapper.message(m, groupId))
        .toList();
    if (messages.isEmpty) {
      final page = await legacy.searchMessages(
        workspaceId,
        groupId,
        query: query,
        pinned: pinned,
      );
      return ChatMessagePage(
        messages: page.messages,
        nextCursor: page.nextCursor == null
            ? null
            : 'legacy:${page.nextCursor}',
      );
    }
    return ChatMessagePage(
      messages: messages,
      nextCursor: result.next ?? 'legacy:',
    );
  });
}
