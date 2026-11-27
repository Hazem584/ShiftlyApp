import 'dart:async';

import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/presentation/cubit/attendance_calendar_cubit_state.dart';
import 'package:shiftly/features/attendance/presentation/cubit/attendance_calendar_load_cubit.dart';

export 'attendance_calendar_cubit_state.dart';

class AttendanceCalendarCubit extends AttendanceCalendarLoadCubit {
  AttendanceCalendarCubit(super.repository, {super.now, super.employee});

  void bindSession(FeatureSessionScope? nextScope) {
    final authorized =
        (employee
            ? nextScope?.isEmployee == true
            : nextScope?.isManager == true)
        ? nextScope
        : null;
    if (scope == authorized) return;
    deadline?.cancel();
    scope = authorized;
    generation += 1;
    requestId += 1;
    requestActive = false;
    followUpRequested = false;
    opened = false;
    emit(const AttendanceCalendarState());
  }

  Future<void> open() async {
    if (opened) return;
    opened = true;
    await load();
  }

  @override
  Future<void> load({bool refresh = false}) async {
    final activeScope = scope;
    if (activeScope == null) return;
    if (requestActive) {
      followUpRequested = true;
      return;
    }
    final localNow = WorkspaceTime.inWorkspace(
      nowFn().toUtc(),
      activeScope.timezone,
    );
    final year = state.year ?? localNow.year;
    final month = state.month ?? localNow.month;
    await performLoad(activeScope, year, month, refresh: refresh);
  }

  Future<void> showCurrentMonth() async {
    final activeScope = scope;
    if (activeScope == null) return;
    opened = true;
    final today = WorkspaceTime.inWorkspace(
      nowFn().toUtc(),
      activeScope.timezone,
    );
    if (state.year == today.year && state.month == today.month) {
      await load(refresh: state.hasData);
      return;
    }
    requestId += 1;
    requestActive = false;
    followUpRequested = false;
    emit(AttendanceCalendarState(year: today.year, month: today.month));
    await load();
  }

  Future<void> previousMonth() => _moveMonth(-1);
  Future<void> nextMonth() => _moveMonth(1);

  Future<void> _moveMonth(int delta) async {
    final activeScope = scope;
    if (activeScope == null) return;
    final localNow = WorkspaceTime.inWorkspace(
      nowFn().toUtc(),
      activeScope.timezone,
    );
    final current = DateTime(
      state.year ?? localNow.year,
      state.month ?? localNow.month,
    );
    final target = DateTime(current.year, current.month + delta);
    requestId += 1;
    requestActive = false;
    followUpRequested = false;
    emit(
      AttendanceCalendarState(
        year: target.year,
        month: target.month,
        loading: true,
      ),
    );
    await performLoad(activeScope, target.year, target.month);
  }

  void selectDate(DateTime date) {
    if (date.year != state.year || date.month != state.month) return;
    emit(
      state.copyWith(selectedDate: DateTime(date.year, date.month, date.day)),
    );
  }

  void invalidate() {
    if (scope == null || !opened) return;
    unawaited(load(refresh: state.hasData));
  }
}
