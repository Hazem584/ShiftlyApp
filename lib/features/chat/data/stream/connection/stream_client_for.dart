import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import 'stream_connect.dart';
import 'stream_connection_state.dart';

Future<stream.StreamChatClient?> streamClientFor(
  StreamConnectionState state,
  String workspaceId,
) {
  final current = state.scope;
  if (current == null || current.workspaceId != workspaceId) {
    throw StateError('Chat session is no longer active.');
  }
  final generation = state.generation;
  return state.connecting ??= connectStream(state, current, generation)
      .catchError((Object error) {
        if (state.generation == generation) state.connecting = null;
        throw error;
      });
}
