import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

import '../stream_chat_repository_base.dart';

mixin StreamListMessages on StreamChatRepositoryBase {
  @override
  Future<ChatMessagePage> listMessages(
    String workspaceId,
    String groupId, {
    String? cursor,
    int limit = 30,
  }) =>
      history.listMessages(workspaceId, groupId, cursor: cursor, limit: limit);
}
