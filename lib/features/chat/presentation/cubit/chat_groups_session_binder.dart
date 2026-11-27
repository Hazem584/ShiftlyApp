import 'dart:async';

import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_realtime.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_session_repository.dart';

import 'chat_groups_cubit.dart';

void bindChatGroupsSession(
  ChatGroupsCubit cubit,
  FeatureSessionScope? scope,
) {
  final authorized =
      scope?.isManager == true || scope?.isEmployee == true ? scope : null;
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
    if (cubit.realtime case final ChatLiveRealtime live) {
      cubit.inboxSubscription = live.subscribeToInbox(
        authorized.workspaceId,
        authorized.membershipId,
        () {
          cubit.inboxDebounce?.cancel();
          cubit.inboxDebounce = Timer(const Duration(milliseconds: 100), () {
            if (cubit.scopeCurrent(authorized, expected)) {
              unawaited(cubit.load(refresh: true));
            }
          });
        },
      );
    }
    unawaited(cubit.load());
  }
}
