import 'dart:async';

import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_realtime.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_session_repository.dart';

import 'chat_groups_cubit.dart';
import 'chat_groups_inbox.dart';

void bindChatGroupsSession(ChatGroupsCubit cubit, FeatureSessionScope? scope) {
  final authorized = scope?.isManager == true || scope?.isEmployee == true
      ? scope
      : null;
  if (cubit.sessionScope == authorized) return;
  unawaited(cubit.inboxSubscription?.cancel());
  cubit.inboxSubscription = null;
  cubit.inboxDebounce?.cancel();
  cubit.groupsRestored = false;
  cubit.messageCache?.storage.bindSession(authorized);
  cubit.sessionScope = authorized;
  if (cubit.repository case final ChatSessionRepository sessionAware) {
    sessionAware.bindChatSession(authorized);
  }
  cubit.resetSessionCounters();
  cubit.emitState(const ChatGroupsState());
  if (authorized != null) {
    final expected = cubit.generation;
    void resync() => cubit.scheduleInboxRefresh(authorized, expected);

    final realtime = cubit.realtime;
    if (realtime is ChatInboxRealtime) {
      cubit.inboxSubscription = realtime.subscribeToInboxActivity(
        authorized.workspaceId,
        authorized.membershipId,
        (activity) {
          if (!cubit.scopeCurrent(authorized, expected)) return;
          applyGroupsInboxActivity(cubit, activity, authorized.membershipId);
          resync();
        },
        resync,
      );
    } else if (realtime is ChatLiveRealtime) {
      cubit.inboxSubscription = realtime.subscribeToInbox(
        authorized.workspaceId,
        authorized.membershipId,
        resync,
      );
    }
    unawaited(cubit.load());
  }
}
