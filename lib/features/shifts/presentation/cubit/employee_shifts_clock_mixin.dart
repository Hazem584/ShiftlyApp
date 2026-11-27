import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/shifts/presentation/cubit/employee_shifts_base.dart';

mixin EmployeeShiftsClockMixin on EmployeeShiftsCubitBase {
  Future<ClockMutationResult> clockIn(String shiftId) =>
      _clock(shiftId, clockIn: true);

  Future<ClockMutationResult> clockOut(String shiftId) =>
      _clock(shiftId, clockIn: false);

  Future<ClockMutationResult> _clock(
    String shiftId, {
    required bool clockIn,
  }) async {
    final currentScope = scope;
    if (currentScope == null) return ClockMutationResult.failure;
    final active = clockIn ? state.clockingInIds : state.clockingOutIds;
    if (active.contains(shiftId)) return ClockMutationResult.busy;
    final gen = generation, next = {...active, shiftId};
    emit(
      clockIn
          ? state.copyWith(clockingInIds: next, clearFailure: true)
          : state.copyWith(clockingOutIds: next, clearFailure: true),
    );
    try {
      final res = clockIn
          ? await attendance.clockIn(shiftId)
          : await attendance.clockOut(shiftId);
      if (!isScopeCurrent(currentScope, gen)) return ClockMutationResult.stale;
      if (!_isValid(res, currentScope.workspaceId, shiftId)) {
        finishClock(
          shiftId,
          clockIn: clockIn,
          failure: const Failure(
            message: 'The server returned an invalid attendance response.',
            kind: FailureKind.server,
          ),
        );
        return ClockMutationResult.failure;
      }
      applyClockSuccess(shiftId, clockIn: clockIn, res: res);
      await onAttendanceChanged?.call();
      onDashboardChanged?.call();
      return ClockMutationResult.success;
    } catch (error) {
      if (!isScopeCurrent(currentScope, gen)) return ClockMutationResult.stale;
      finishClock(
        shiftId,
        clockIn: clockIn,
        failure: failure(
          error,
          clockIn ? 'Unable to clock in.' : 'Unable to clock out.',
        ),
      );
      return ClockMutationResult.failure;
    }
  }

  bool _isValid(
    AttendanceRecordApi res,
    String workspaceId,
    String shiftId,
  ) =>
      res.workspaceId == workspaceId &&
      res.shiftId == shiftId &&
      res.source == AttendanceSource.legacyShift &&
      res.shift != null;
}
