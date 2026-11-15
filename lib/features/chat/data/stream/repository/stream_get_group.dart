import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

import '../stream_chat_mapper.dart';
import '../stream_chat_repository_base.dart';
import '../stream_chat_request.dart';

mixin StreamGetGroup on StreamChatRepositoryBase {
  @override
  Future<ChatGroup> getGroup(String workspaceId, String groupId) =>
      streamChatRequest(() async {
        final base = await legacy.getGroup(workspaceId, groupId);
        if (!await streamEnabled(workspaceId)) return base;
        return StreamChatMapper.group(
          base,
          await connection.channel(workspaceId, groupId),
        );
      });
}
