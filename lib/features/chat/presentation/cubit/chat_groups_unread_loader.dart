import 'dart:async';

import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';

Future<void> refreshChatGroupsUnread(ChatGroupsCubit cubit) async {
  final scope = cubit.scope;
  if (scope == null) return;
  if (cubit.unreadRefreshing) {
    cubit.unreadRefreshQueued = true;
    return;
  }
  cubit.unreadRefreshing = true;
  final generation = cubit.generation;
  final request = ++cubit.unreadRequest;
  final unreadSequence = ++cubit.unreadIssuedSequence;
  try {
    final value = await cubit.repository.unreadCount(scope.workspaceId);
    if (cubit.unreadCurrent(scope, generation, request) &&
        cubit.acceptUnreadResult(scope, generation, unreadSequence)) {
      cubit.emitState(cubit.state.copyWith(unreadCount: value));
    }
  } catch (_) {
    // Background badge refreshes preserve the last canonical count.
  } finally {
    if (cubit.unreadCurrent(scope, generation, request)) {
      cubit.unreadRefreshing = false;
      if (cubit.unreadRefreshQueued) {
        cubit.unreadRefreshQueued = false;
        unawaited(cubit.refreshUnread());
      }
    }
  }
}
