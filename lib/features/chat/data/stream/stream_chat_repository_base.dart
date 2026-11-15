import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_session_repository.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import 'stream_chat_connection.dart';
import 'stream_chat_history.dart';
import 'stream_chat_media.dart';
import 'stream_send_message.dart' as sending;

abstract class StreamChatRepositoryBase extends ChatRepository
    implements ChatSessionRepository {
  StreamChatRepositoryBase(this.legacy, this.connection)
    : media = StreamChatMedia(connection),
      history = StreamChatHistory(legacy, connection);
  final ChatRepository legacy;
  final StreamChatConnection connection;
  final StreamChatMedia media;
  final StreamChatHistory history;
  Future<List<ChatGroup>>? groupsRequest;
  @override
  void bindChatSession(FeatureSessionScope? scope) {
    connection.bind(scope);
    media.reset();
    history.reset();
    groupsRequest = null;
  }

  Future<bool> streamEnabled(String workspaceId) async =>
      await connection.clientFor(workspaceId) != null;
  Future<ChatMessage> sendStreamMessage(
    String workspaceId,
    String groupId,
    stream.Message message,
  ) => sending.sendStreamMessage(
    connection,
    history,
    workspaceId,
    groupId,
    message,
  );
}
