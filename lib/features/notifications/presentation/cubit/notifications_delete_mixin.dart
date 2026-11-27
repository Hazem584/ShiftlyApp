import 'dart:async';

import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_cubit_base.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_mutation_mixin.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_state.dart';

mixin NotificationsDeleteMixin
    on NotificationsCubitBase, NotificationsMutationMixin {
  Future<void> loadMore() async {
    final activeScope = currentScope, previous = state;
    if (activeScope == null ||
        listInFlight ||
        previous.loadingMore ||
        !previous.hasMore) {
      return;
    }
    listInFlight = true;
    final gen = generation, requestId = ++listRequestId;
    emit(previous.copyWith(loadingMore: true, clearFailure: true));
    try {
      final q = previous.query.copyWith(page: previous.page + 1);
      final page = await repository.list(activeScope.workspaceId, q);
      if (!isCurrentList(activeScope, gen, requestId)) return;
      validatePage(activeScope, page);
      final ids = previous.notifications.map((item) => item.id).toSet();
      final merged = [
        ...previous.notifications,
        ...page.data.where((item) => ids.add(item.id)),
      ];
      emit(
        previous.copyWith(
          notifications: merged,
          page: page.pagination.page,
          totalPages: page.pagination.totalPages,
          loadingMore: false,
        ),
      );
    } catch (error) {
      if (!isCurrentList(activeScope, gen, requestId)) return;
      final err = toFailure(error, 'Unable to load more notifications.');
      emit(previous.copyWith(loadingMore: false, failure: err));
    } finally {
      if (isScopeCurrent(activeScope, gen)) listInFlight = false;
    }
  }

  Future<NotificationMutationResult> delete(String notificationId) async {
    final activeScope = currentScope;
    if (activeScope == null) return NotificationMutationResult.failure;
    if (state.deletingIds.contains(notificationId)) {
      return NotificationMutationResult.busy;
    }
    final gen = generation;
    final ids = {...state.deletingIds, notificationId};
    emit(state.copyWith(deletingIds: ids, clearFailure: true));
    try {
      final deleted = await repository.delete(notificationId);
      if (!isScopeCurrent(activeScope, gen)) {
        return NotificationMutationResult.stale;
      }
      if (!deleted) {
        const err = Failure(
          message: 'The server did not confirm deletion.',
          kind: FailureKind.server,
        );
        finishDelete(notificationId, failure: err);
        return NotificationMutationResult.failure;
      }
      finishDelete(notificationId, remove: true);
      unawaited(refreshUnreadCount());
      return NotificationMutationResult.success;
    } catch (error) {
      if (!isScopeCurrent(activeScope, gen)) {
        return NotificationMutationResult.stale;
      }
      final err = toFailure(error, 'Unable to delete the notification.');
      finishDelete(notificationId, failure: err);
      return NotificationMutationResult.failure;
    }
  }
}
