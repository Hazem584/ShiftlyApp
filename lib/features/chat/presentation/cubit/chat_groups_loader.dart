import 'dart:async';

import 'package:shiftly/features/chat/presentation/cubit/chat_groups_access_sync.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cache_helper.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';

Future<void> loadChatGroupsList(
  ChatGroupsCubit cubit, {
  bool refresh = false,
}) async {
  final scope = cubit.scope;
  if (scope == null) return;
  if (cubit.loadingGroups) {
    if (refresh) cubit.refreshQueued = true;
    return;
  }
  cubit.loadingGroups = true;
  final generation = cubit.generation, request = ++cubit.request;
  final cacheRevision = cubit.messageCache?.storage.revision;
  final unreadSeq = ++cubit.unreadIssuedSequence, previous = cubit.state;
  cubit.emitState(
    !previous.loading
        ? previous.copyWith(refreshing: true, clearFailure: true)
        : ChatGroupsState(unreadCount: previous.unreadCount),
  );
  try {
    if (!cubit.groupsRestored &&
        cubit.groupCache != null &&
        !await restoreCachedChatGroups(cubit, scope, generation, request)) {
      return;
    }
    final unread = cubit.repository
        .unreadCount(scope.workspaceId)
        .then<int?>((v) => v, onError: (Object _) => null);
    final groups = await cubit.repository.listGroups(scope.workspaceId);
    if (!cubit.current(scope, generation, request) ||
        cacheRevision != cubit.messageCache?.storage.revision) {
      return;
    }
    syncChatGroupsCacheAccess(
      cubit.messageCache,
      scope,
      previous.groups,
      groups,
    );
    cubit.emitState(
      cubit.state.copyWith(loading: false, groups: groups, refreshing: false),
    );
    persistChatGroupsCache(cubit, scope, groups);
    final count = await unread;
    if (!cubit.current(scope, generation, request) ||
        cacheRevision != cubit.messageCache?.storage.revision) {
      return;
    }
    if (count != null &&
        cubit.acceptUnreadResult(scope, generation, unreadSeq)) {
      cubit.emitState(cubit.state.copyWith(unreadCount: count));
      persistChatGroupsCache(cubit, scope, groups);
    }
  } catch (error) {
    if (!cubit.current(scope, generation, request)) return;
    cubit.emitState(
      cubit.state.copyWith(
        loading: false,
        refreshing: false,
        failure: chatGroupsFailure(error, 'Unable to load chat groups.'),
      ),
    );
  } finally {
    cubit.finishGroupsLoad(scope, generation);
  }
}
