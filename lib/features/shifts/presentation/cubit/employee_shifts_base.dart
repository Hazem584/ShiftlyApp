import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';
import 'package:shiftly/features/shifts/presentation/cubit/employee_shifts_state.dart';

export 'package:shiftly/features/shifts/presentation/cubit/employee_shifts_state.dart';

abstract class EmployeeShiftsCubitBase extends Cubit<EmployeeShiftsState> {
  EmployeeShiftsCubitBase(
    this.shifts,
    this.attendance, {
    this.onAttendanceChanged,
    this.onDashboardChanged,
  }) : super(const EmployeeShiftsState());

  final ShiftRepository shifts;
  final AttendanceRepository attendance;
  final Future<void> Function()? onAttendanceChanged;
  final void Function()? onDashboardChanged;
  FeatureSessionScope? scope;
  var generation = 0;
  var requestId = 0;

  Failure failure(Object error, String fallback) =>
      error is ApiException ? error.toFailure() : Failure(message: fallback);

  bool isCurrent(FeatureSessionScope s, int g, int r) =>
      isScopeCurrent(s, g) && requestId == r;

  bool isScopeCurrent(FeatureSessionScope s, int g) =>
      !isClosed && scope == s && generation == g;

  void applyClockSuccess(
    String shiftId, {
    required bool clockIn,
    required AttendanceRecordApi res,
  }) {
    final summary = ShiftAttendanceSummary(
      id: res.id,
      clockInAt: res.clockInAt,
      clockOutAt: res.clockOutAt,
      reviewStatus: res.reviewStatus,
      minutesLate: res.minutesLate,
      workedMinutes: res.workedMinutes,
    );
    final updated = state.records
        .map(
          (i) => i.id == shiftId
              ? i.copyWith(status: res.shift!.status, attendance: summary)
              : i,
        )
        .toList(growable: false);
    final sel = state.selected?.id == shiftId
        ? state.selected!.copyWith(
            status: res.shift!.status,
            attendance: summary,
          )
        : state.selected;
    finishClock(shiftId, clockIn: clockIn, records: updated, selected: sel);
  }

  void finishClock(
    String shiftId, {
    required bool clockIn,
    List<ShiftRecord>? records,
    ShiftRecord? selected,
    Failure? failure,
  }) {
    final values = {...(clockIn ? state.clockingInIds : state.clockingOutIds)}
      ..remove(shiftId);
    emit(
      state.copyWith(
        records: records,
        selected: selected,
        clockingInIds: clockIn ? values : state.clockingInIds,
        clockingOutIds: clockIn ? state.clockingOutIds : values,
        failure: failure,
      ),
    );
  }
}
