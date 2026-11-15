import '../stream_chat_repository_base.dart';
import '../stream_chat_request.dart';

mixin StreamUnreadCount on StreamChatRepositoryBase {
  @override
  Future<int> unreadCount(String workspaceId) => streamChatRequest(() async {
    if (!await streamEnabled(workspaceId)) {
      return legacy.unreadCount(workspaceId);
    }
    final groups = await listGroups(workspaceId);
    return groups.fold<int>(0, (sum, g) => sum + g.unreadCount);
  });
}
