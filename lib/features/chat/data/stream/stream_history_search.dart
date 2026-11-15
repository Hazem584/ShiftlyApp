import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import 'stream_chat_connection.dart';
import 'stream_chat_mapper.dart';
import 'stream_chat_request.dart';
import 'stream_legacy_page.dart';

Future<ChatMessagePage> searchStreamMessages(
  ChatRepository legacy,
  StreamChatConnection connection,
  String workspaceId,
  String groupId, {
  String? query,
  bool pinned = false,
  String? cursor,
}) => streamChatRequest(() async {
  if (await connection.clientFor(workspaceId) == null) {
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
    return legacyStreamPage(page);
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
    return legacyStreamPage(page);
  }
  return ChatMessagePage(
    messages: messages,
    nextCursor: result.next ?? 'legacy:',
  );
});
