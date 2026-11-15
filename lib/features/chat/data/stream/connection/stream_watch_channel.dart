import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import 'stream_connection_state.dart';

Future<stream.Channel> watchStreamChannel(
  StreamConnectionState state,
  String workspaceId,
  String groupId,
  Future<stream.StreamChatClient?> Function(String) clientFor,
) async {
  final client = await clientFor(workspaceId);
  if (client == null) throw StateError('Stream is not enabled.');
  final existing = client.channel('shiftly', id: groupId);
  if (state.watched.contains(groupId)) return existing;
  return state.watching
      .putIfAbsent(groupId, () async {
        final current = state.scope!, generation = state.generation;
        await state.api.post<Object?>(
          '/workspaces/$workspaceId/chat/stream/groups/$groupId',
        );
        state.check(current, generation);
        await existing.watch();
        state.check(current, generation);
        state.watched.add(groupId);
        return existing;
      })
      .whenComplete(() => state.watching.remove(groupId));
}
