import 'dart:async';

import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_cubit_base.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_state.dart';

mixin NotificationsMutationMixin on NotificationsCubitBase {
  Future<void> refreshUnreadCount() async {
    final activeScope = currentScope;
    if (activeScope == null) return;
    final gen = generation, requestId = ++countRequestId;
    try {
      final count = await repository.unreadCount();
      if (!isCurrentCount(activeScope, gen, requestId)) return;
      emit(state.copyWith(unreadCount: count));
    } catch (error) {
      if (!isCurrentCount(activeScope, gen, requestId)) return;
      final err = toFailure(error, 'Unable to refresh unread notifications.');
      emit(state.copyWith(failure: err));
    }
  }

  Future<NotificationMutationResult> markRead(String notificationId) async {
    final activeScope = currentScope;
    if (activeScope == null) return NotificationMutationResult.failure;
    if (state.markingIds.contains(notificationId)) {
      return NotificationMutationResult.busy;
    }
    final current = state.notifications
        .where((item) => item.id == notificationId)
        .firstOrNull;
    if (current != null && !current.isUnread) {
      return NotificationMutationResult.success;
    }
    final gen = generation;
    final ids = {...state.markingIds, notificationId};
    emit(state.copyWith(markingIds: ids, clearFailure: true));
    try {
      final record = await repository.markRead(notificationId);
      if (!isScopeCurrent(activeScope, gen)) {
        return NotificationMutationResult.stale;
      }
      if (record.id != notificationId ||
          record.readAt == null ||
          record.workspaceId != activeScope.workspaceId) {
        finishMark(
          notificationId,
          failure: const Failure(
            message: 'The server returned an invalid notification.',
            kind: FailureKind.server,
          ),
        );
        return NotificationMutationResult.failure;
      }
      finishMark(notificationId, record: record);
      unawaited(refreshUnreadCount());
      return NotificationMutationResult.success;
    } catch (error) {
      if (!isScopeCurrent(activeScope, gen)) {
        return NotificationMutationResult.stale;
      }
      final err = toFailure(error, 'Unable to mark the notification as read.');
      finishMark(notificationId, failure: err);
      return NotificationMutationResult.failure;
    }
  }
}
