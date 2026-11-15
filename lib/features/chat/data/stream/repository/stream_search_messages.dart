import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

import '../stream_chat_repository_base.dart';

mixin StreamSearchMessages on StreamChatRepositoryBase {
  @override
  Future<ChatMessagePage> searchMessages(
    String workspaceId,
    String groupId, {
    String? query,
    bool pinned = false,
    String? cursor,
  }) => history.searchMessages(
    workspaceId,
    groupId,
    query: query,
    pinned: pinned,
    cursor: cursor,
  );
}
