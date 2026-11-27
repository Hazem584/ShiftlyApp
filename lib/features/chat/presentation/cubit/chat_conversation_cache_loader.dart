import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_pager.dart';

Future<bool> restoreChatConversationCache(
  ChatConversationPager pager,
  FeatureSessionScope scope,
  String groupId,
  int generation,
  int request,
) async {
  final host = pager.host;
  final cacheScope = host.cacheScope;
  final cache = host.messageCache;
  if (pager.cacheRestored || cacheScope == null || cache == null) return true;
  if (!cache.storage.authorized(cacheScope)) {
    final group = await (pager.loadGroup?.call() ??
        host.repository.getGroup(scope.workspaceId, groupId));
    if (!pager.current(scope, groupId, generation, request)) return false;
    if (group.id != groupId || group.workspaceId != scope.workspaceId) {
      throw const FormatException('Invalid group');
    }
    cache.storage.grant(cacheScope, archived: group.isArchived);
  }
  final cached = await cache.read(cacheScope).catchError((Object _) => null);
  if (!pager.current(scope, groupId, generation, request)) return false;
  pager.cacheRestored = true;
  pager.latestLoaded = cached?.messages.isNotEmpty == true;
  if (cached != null) {
    host.emitState(
      host.state.copyWith(
        loading: false,
        messages: host.mergeMessages(cached.messages, host.state.messages),
        nextCursor: cached.nextCursor,
        clearCursor: cached.nextCursor == null,
        refreshing: true,
      ),
    );
  }
  await pager.restoreOutbox();
  return pager.current(scope, groupId, generation, request);
}
