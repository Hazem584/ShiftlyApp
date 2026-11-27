import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import '../../domain/entities/chat_inbox_activity.dart';
import 'stream_chat_connection.dart';
import 'stream_chat_history.dart';
import 'stream_chat_mapper.dart';

Future<ChatMessage> sendStreamMessage(
  StreamChatConnection connection,
  StreamChatHistory history,
  String workspaceId,
  String groupId,
  stream.Message message,
) async {
  final generation = connection.generation;
  final channel = await connection.channel(workspaceId, groupId);
  ChatMessage confirm(stream.Message value) {
    final confirmed = StreamChatMapper.message(value, groupId);
    connection.publishInboxActivity(generation, ChatInboxMessage(confirmed));
    return confirmed;
  }

  try {
    final response = await channel.sendMessage(message, skipEnrichUrl: true);
    return confirm(response.message);
  } on stream.StreamChatNetworkError catch (error) {
    if (error.statusCode == 409) {
      final existing = await history.find(workspaceId, groupId, message.id);
      if (existing != null) {
        return confirm(existing);
      }
    }
    rethrow;
  }
}
