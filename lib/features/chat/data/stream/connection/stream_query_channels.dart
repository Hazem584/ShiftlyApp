import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import 'stream_connection_state.dart';

Future<Map<String, stream.Channel>> queryStreamChannels(
  StreamConnectionState state,
  String workspaceId,
  Set<String> allowed,
  Future<stream.StreamChatClient?> Function(String) clientFor,
  Future<stream.Channel> Function(String, String) channel,
) async {
  final client = await clientFor(workspaceId);
  if (client == null) return {};
  final current = state.scope!, generation = state.generation;
  final found = <String, stream.Channel>{};
  if (allowed.every((id) => state.watched.contains(id))) {
    return {for (final id in allowed) id: client.channel('shiftly', id: id)};
  }

  for (var offset = 0; ; offset += 30) {
    final list = await client.queryChannelsOnline(
      filter: stream.Filter.and([
        stream.Filter.equal('type', 'shiftly'),
        stream.Filter.equal('shiftly_workspace_id', workspaceId),
        stream.Filter.in_('members', [current.membershipId]),
      ]),
      paginationParams: stream.PaginationParams(limit: 30, offset: offset),
      messageLimit: 1,
      memberLimit: 0,
    );
    state.check(current, generation);
    for (final channel in list) {
      if (allowed.contains(channel.id)) {
        found[channel.id!] = channel;
        state.watched.add(channel.id!);
      }
    }
    if (list.length < 30) break;
  }
  for (final id in allowed.difference(found.keys.toSet())) {
    found[id] = await channel(workspaceId, id);
  }
  return found;
}
