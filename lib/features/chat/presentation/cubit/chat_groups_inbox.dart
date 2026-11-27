import 'dart:math' as math;

import '../../domain/entities/chat_group.dart';
import '../../domain/entities/chat_inbox_activity.dart';
import '../../domain/services/chat_inbox_updates.dart';
import 'chat_groups_cubit.dart';

void applyGroupsInboxActivity(
  ChatGroupsCubit cubit,
  ChatInboxActivity activity,
  String membershipId,
) {
  final state = cubit.state;
  final index = state.groups.indexWhere((g) => g.id == activity.groupId);
  if (index == -1) return;
  final previous = state.groups[index];
  final updated = applyChatInboxActivity(previous, activity, membershipId);
  if (identical(updated, previous)) return;
  final groups = List<ChatGroup>.of(state.groups)..[index] = updated;
  cubit.inboxRevision++;
  cubit.unreadAppliedSequence = ++cubit.unreadIssuedSequence;
  final unread = state.unreadCount + updated.unreadCount - previous.unreadCount;
  cubit.emitState(
    state.copyWith(groups: groups, unreadCount: math.max(0, unread)),
  );
}
