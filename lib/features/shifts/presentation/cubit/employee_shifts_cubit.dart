import 'dart:async';

import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';
import 'package:shiftly/features/shifts/presentation/cubit/employee_shifts_base.dart';
import 'package:shiftly/features/shifts/presentation/cubit/employee_shifts_clock_mixin.dart';
import 'package:shiftly/features/shifts/presentation/cubit/employee_shifts_details_mixin.dart';

export 'package:shiftly/features/shifts/presentation/cubit/employee_shifts_state.dart';

class EmployeeShiftsCubit extends EmployeeShiftsCubitBase
    with EmployeeShiftDetailsMixin, EmployeeShiftsClockMixin {
  EmployeeShiftsCubit(
    super.shifts,
    super.attendance, {
    super.onAttendanceChanged,
    super.onDashboardChanged,
  });

  void bindSession(FeatureSessionScope? nextScope) {
    final authorized = nextScope?.isEmployee == true ? nextScope : null;
    if (scope == authorized) return;
    scope = authorized;
    generation += 1;
    requestId += 1;
    emit(const EmployeeShiftsState());
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
          : EmployeeShiftsState(query: requested),
    );
    try {
      final page = await shifts.listMyShifts(
        currentScope.workspaceId,
        requested.copyWith(page: 1),
      );
      if (!isCurrent(currentScope, gen, req)) return;
      final records = page.data
          .where((item) => item.workspaceId == currentScope.workspaceId)
          .toList(growable: false);
      emit(
        EmployeeShiftsState(
          initialLoading: false,
          records: records,
          query: requested.copyWith(page: 1),
          page: page.pagination.page,
          totalPages: page.pagination.totalPages,
        ),
      );
    } catch (error) {
      if (!isCurrent(currentScope, gen, req)) return;
      final err = failure(error, 'Unable to load your shifts.');
      emit(
        refresh && previous.records.isNotEmpty
            ? previous.copyWith(refreshing: false, failure: err)
            : EmployeeShiftsState(
                initialLoading: false,
                query: requested,
                failure: err,
              ),
      );
    }
  }
}
