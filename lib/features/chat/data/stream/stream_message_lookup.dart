import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import 'stream_chat_connection.dart';

Future<stream.Message?> findStreamMessage(
  StreamChatConnection connection,
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
