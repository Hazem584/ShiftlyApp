import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

import '../stream_chat_mapper.dart';
import '../stream_chat_repository_base.dart';
import '../stream_chat_request.dart';

mixin StreamListGroups on StreamChatRepositoryBase {
  @override
  Future<List<ChatGroup>> listGroups(String workspaceId) {
    final existing = groupsRequest;
    if (existing != null) return existing;
    late final Future<List<ChatGroup>> request;
    request =
        streamChatRequest(() async {
          final base = await legacy.listGroups(workspaceId);
          if (!await streamEnabled(workspaceId)) return base;
          final client = (await connection.clientFor(workspaceId))!;
          final counts = client.getUnreadCount().then<Map<String, int>?>(
            (value) => {
              for (final item in value.channels)
                item.channelId: item.unreadCount,
            },
            onError: (Object _) => null,
          );
          final channels = await connection.channels(
            workspaceId,
            base.map((g) => g.id).toSet(),
          );
          final unread = await counts;
          return [
            for (final group in base)
              if (channels[group.id] != null)
                StreamChatMapper.group(
                  group,
                  channels[group.id]!,
                  streamUnreadCount: unread == null
                      ? null
                      : unread['shiftly:${group.id}'] ?? 0,
                ),
          ];
        }).whenComplete(() {
          if (identical(groupsRequest, request)) groupsRequest = null;
        });
    groupsRequest = request;
    return request;
  }
}
