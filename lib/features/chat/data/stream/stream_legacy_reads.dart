import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';

import 'stream_chat_connection.dart';

class StreamLegacyReads {
  StreamLegacyReads(this.legacy, this.connection);

  final ChatRepository legacy;
  final StreamChatConnection connection;
  final _earlierRead = <String, Future<void>>{};

  void reset() => _earlierRead.clear();

  Future<void> markEarlierRead(String workspaceId, String groupId) {
    final key = '$workspaceId:$groupId';
    return _earlierRead.putIfAbsent(key, () {
      final generation = connection.generation;
      return _markLatestLegacyRead(workspaceId, groupId, generation).catchError(
        (Object error) {
          if (generation == connection.generation) _earlierRead.remove(key);
          throw error;
        },
      );
    });
  }

  Future<void> _markLatestLegacyRead(
    String workspaceId,
    String groupId,
    int generation,
  ) async {
    final page = await legacy.listMessages(workspaceId, groupId, limit: 1);
    if (generation != connection.generation || page.messages.isEmpty) return;
    try {
      await legacy.markRead(workspaceId, groupId, page.messages.first.id);
    } on ApiException catch (error) {
      if (error.code != 'CHAT_READ_POSITION_BACKWARDS') rethrow;
    }
  }
}
