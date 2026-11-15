import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import 'stream_chat_connection.dart';
import 'stream_chat_mapper.dart';
import 'stream_chat_request.dart';
import 'stream_legacy_page.dart';

Future<ChatMessagePage> listStreamMessages(
  ChatRepository legacy,
  StreamChatConnection connection,
  String workspaceId,
  String groupId, {
  String? cursor,
  int limit = 30,
}) => streamChatRequest(() async {
  if (await connection.clientFor(workspaceId) == null) {
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
    return legacyStreamPage(page);
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
    final page = await legacy.listMessages(workspaceId, groupId, limit: limit);
    return legacyStreamPage(page);
  }
  return ChatMessagePage(
    messages: list.map((m) => StreamChatMapper.message(m, groupId)).toList(),
    nextCursor: raw.length < limit
        ? 'legacy:'
        : 'stream:${(List<stream.Message>.of(raw)..sort((a, b) => a.createdAt.compareTo(b.createdAt))).first.id}',
  );
});
