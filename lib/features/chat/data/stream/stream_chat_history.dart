import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import 'stream_chat_connection.dart';
import 'stream_history_listing.dart';
import 'stream_history_search.dart';
import 'stream_legacy_reads.dart';
import 'stream_message_lookup.dart';

class StreamChatHistory {
  StreamChatHistory(this.legacy, this.connection)
    : legacyReads = StreamLegacyReads(legacy, connection);

  final ChatRepository legacy;
  final StreamChatConnection connection;
  final StreamLegacyReads legacyReads;

  void reset() => legacyReads.reset();

  Future<stream.Message?> find(String workspaceId, String groupId, String id) =>
      findStreamMessage(connection, workspaceId, groupId, id);
  Future<ChatMessagePage> listMessages(
    String workspaceId,
    String groupId, {
    String? cursor,
    int limit = 30,
  }) => listStreamMessages(
    legacy,
    connection,
    workspaceId,
    groupId,
    cursor: cursor,
    limit: limit,
  );
  Future<ChatMessagePage> searchMessages(
    String workspaceId,
    String groupId, {
    String? query,
    bool pinned = false,
    String? cursor,
  }) => searchStreamMessages(
    legacy,
    connection,
    workspaceId,
    groupId,
    query: query,
    pinned: pinned,
    cursor: cursor,
  );
}
