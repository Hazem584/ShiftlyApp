import 'dart:async';

import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_cubit_base.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_delete_mixin.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_load_mixin.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_mutation_mixin.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_state.dart';

export 'package:shiftly/features/notifications/presentation/cubit/notifications_state.dart';

class NotificationsCubit extends NotificationsCubitBase
    with
        NotificationsLoadMixin,
        NotificationsMutationMixin,
        NotificationsDeleteMixin {
  NotificationsCubit(super.repository);

  void bindSession(FeatureSessionScope? scope) {
    final authorized = scope?.isManager == true || scope?.isEmployee == true
        ? scope
        : null;
    if (currentScope == authorized) return;
    currentScope = authorized;
    generation += 1;
    listRequestId += 1;
    countRequestId += 1;
    listInFlight = false;
    emit(const NotificationsState());
    if (authorized != null) unawaited(load());
  }

  Future<NotificationMutationResult> markAllRead() async {
    final activeScope = currentScope;
    if (activeScope == null) return NotificationMutationResult.failure;
    if (state.markingAll) return NotificationMutationResult.busy;
    final gen = generation;
    emit(state.copyWith(markingAll: true, clearFailure: true));
    try {
      await repository.markAllRead(activeScope.workspaceId);
      if (!isScopeCurrent(activeScope, gen)) {
        return NotificationMutationResult.stale;
      }
      emit(state.copyWith(markingAll: false));
      await load(refresh: true);
      return isScopeCurrent(activeScope, gen)
          ? NotificationMutationResult.success
          : NotificationMutationResult.stale;
    } catch (error) {
      if (!isScopeCurrent(activeScope, gen)) {
        return NotificationMutationResult.stale;
      }
      final err = toFailure(error, 'Unable to mark all notifications as read.');
      emit(state.copyWith(markingAll: false, failure: err));
      return NotificationMutationResult.failure;
    }
  }
}
