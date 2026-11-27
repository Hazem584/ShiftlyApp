import 'dart:async';

import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';
import 'package:shiftly/features/shifts/presentation/cubit/manager_shifts_cancel_mixin.dart';
import 'package:shiftly/features/shifts/presentation/cubit/manager_shifts_create_mixin.dart';
import 'package:shiftly/features/shifts/presentation/cubit/manager_shifts_helper.dart';
import 'package:shiftly/features/shifts/presentation/cubit/manager_shifts_load_more_mixin.dart';
import 'package:shiftly/features/shifts/presentation/cubit/manager_shifts_state.dart';
import 'package:shiftly/features/shifts/presentation/cubit/manager_shifts_update_mixin.dart';

export 'package:shiftly/features/shifts/presentation/cubit/manager_shifts_state.dart';

class ManagerShiftsCubit extends ManagerShiftsCubitBase
    with
        ManagerShiftMutations,
        ManagerShiftUpdateMixin,
        ManagerShiftCancelMixin,
        ManagerShiftsLoadMoreMixin {
  ManagerShiftsCubit(super.repository, {super.onDashboardChanged});

  void bindSession(FeatureSessionScope? nextScope) {
    final authorized = nextScope?.isManager == true ? nextScope : null;
    if (scope == authorized) return;
    scope = authorized;
    generation += 1;
    requestId += 1;
    emit(const ManagerShiftsState());
    if (authorized != null) unawaited(load());
  }

  Future<void> load({ShiftQuery? query, bool refresh = false}) async {
    final currentScope = scope;
    if (currentScope == null) return;
    final gen = generation, req = ++requestId;
    final requested = query ?? state.query, previous = state;
    emit(
      refresh && previous.records.isNotEmpty
          ? previous.copyWith(refreshing: true, clearFailure: true)
          : ManagerShiftsState(query: requested),
    );
    try {
      final page = await repository.listWorkspaceShifts(
        currentScope.workspaceId,
        requested.copyWith(page: 1),
      );
      if (!isCurrent(currentScope, gen, req)) return;
      if (page.data.any((i) => i.workspaceId != currentScope.workspaceId)) {
        throw const FormatException('Cross-workspace shift response');
      }
      emit(
        ManagerShiftsState(
          initialLoading: false,
          records: page.data,
          query: requested.copyWith(page: 1),
          page: page.pagination.page,
          total: page.pagination.total,
          totalPages: page.pagination.totalPages,
        ),
      );
    } catch (error) {
      if (!isCurrent(currentScope, gen, req)) return;
      final failure = ManagerShiftsHelper.failure(
        error,
        'Unable to load shifts.',
      );
      emit(
        refresh && previous.records.isNotEmpty
            ? previous.copyWith(refreshing: false, failure: failure)
            : ManagerShiftsState(
                initialLoading: false,
                query: requested,
                failure: failure,
              ),
      );
    }
  }

  static Failure? validateShift({
    required DateTime startsAt,
    required DateTime endsAt,
    required int breakMinutes,
    required int graceMinutes,
  }) => ManagerShiftsHelper.validateShift(
    startsAt: startsAt,
    endsAt: endsAt,
    breakMinutes: breakMinutes,
    graceMinutes: graceMinutes,
  );
}
