import 'dart:async';

import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';

Future<bool> restoreCachedChatGroups(
  ChatGroupsCubit cubit,
  FeatureSessionScope scope,
  int generation,
  int request,
) async {
  if (cubit.groupsRestored || cubit.groupCache == null) return true;
  cubit.groupsRestored = true;
  final cached = await cubit.groupCache!
      .read(scope)
      .catchError((Object _) => null);
  if (!cubit.current(scope, generation, request)) return false;
  if (cached != null) {
    cubit.emitState(
      cubit.state.copyWith(
        loading: false,
        groups: cached.groups,
        unreadCount: cached.unreadCount,
        refreshing: true,
      ),
    );
  }
  return true;
}

void persistChatGroupsCache(
  ChatGroupsCubit cubit,
  FeatureSessionScope scope,
  List<ChatGroup> groups,
) => unawaited(
  cubit.groupCache
          ?.write(scope, (groups: groups, unreadCount: cubit.state.unreadCount))
          .catchError((Object _) {}) ??
      Future<void>.value(),
);
