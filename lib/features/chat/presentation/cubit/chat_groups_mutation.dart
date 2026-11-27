import 'dart:async';

import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_access_sync.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';

Future<ChatMutationResult> mutateChatGroup(
  ChatGroupsCubit cubit,
  Future<Object?> Function(FeatureSessionScope scope) operation,
) async {
  final scope = cubit.scope;
  if (scope == null || !scope.isManager) return ChatMutationResult.failure;
  if (cubit.state.mutating) return ChatMutationResult.busy;
  final generation = cubit.generation;
  cubit.emitState(cubit.state.copyWith(mutating: true, clearFailure: true));
  try {
    await operation(scope);
    if (!cubit.scopeCurrent(scope, generation)) return ChatMutationResult.stale;
    cubit.emitState(cubit.state.copyWith(mutating: false));
    await _refreshAfterMutation(cubit, scope, generation);
    return cubit.scopeCurrent(scope, generation)
        ? ChatMutationResult.success
        : ChatMutationResult.stale;
  } catch (error) {
    if (!cubit.scopeCurrent(scope, generation)) return ChatMutationResult.stale;
    cubit.emitState(
      cubit.state.copyWith(
        mutating: false,
        failure: chatGroupsFailure(error, 'Unable to update the chat group.'),
      ),
    );
    return ChatMutationResult.failure;
  }
}

Future<void> _refreshAfterMutation(
  ChatGroupsCubit cubit,
  FeatureSessionScope scope,
  int generation,
) async {
  final request = ++cubit.request, unreadSeq = ++cubit.unreadIssuedSequence;
  final inboxRevision = cubit.inboxRevision;
  try {
    final res = await Future.wait<Object>([
      cubit.repository.listGroups(scope.workspaceId),
      cubit.repository.unreadCount(scope.workspaceId),
    ]);
    if (!cubit.current(scope, generation, request)) return;
    if (inboxRevision != cubit.inboxRevision) {
      await cubit.load(refresh: true);
      return;
    }
    final groups = res[0] as List<ChatGroup>;
    if (groups.any((g) => g.workspaceId != scope.workspaceId)) {
      throw const FormatException('Cross-workspace chat response');
    }
    cubit.emitState(
      cubit.state.copyWith(
        groups: groups,
        unreadCount: cubit.acceptUnreadResult(scope, generation, unreadSeq)
            ? res[1] as int
            : cubit.state.unreadCount,
        clearFailure: true,
      ),
    );
  } catch (error) {
    if (cubit.current(scope, generation, request)) {
      final msg = 'The change was saved, but chat could not be refreshed.';
      cubit.emitState(
        cubit.state.copyWith(failure: chatGroupsFailure(error, msg)),
      );
    }
  }
}
