import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_helpers.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_page_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_state.dart';

export 'manager_attendance_state.dart';

class ManagerAttendanceCubit extends ManagerAttendancePageCubit {
  ManagerAttendanceCubit(super.repository, {super.onDashboardChanged});

  Future<AttendanceRecordApi?> loadDetails(String attendanceId) async {
    final activeScope = scope;
    if (activeScope == null || state.detailLoading) return null;
    final gen = generation;
    emit(state.copyWith(detailLoading: true, clearFailure: true));
    try {
      final record = await repository.getWorkspaceAttendance(
        activeScope.workspaceId,
        attendanceId,
      );
      if (!isScopeCurrent(activeScope, gen) ||
          record.workspaceId != activeScope.workspaceId) {
        return null;
      }
      emit(state.copyWith(selected: record, detailLoading: false));
      return record;
    } catch (error) {
      if (!isScopeCurrent(activeScope, gen)) return null;
      final failure = attendanceFailure(
        error,
        'Unable to load attendance details.',
      );
      emit(state.copyWith(detailLoading: false, failure: failure));
      return null;
    }
  }

  Future<AttendanceMutationResult> review(
    String attendanceId,
    AttendanceReviewDecision decision, {
    String? rejectionReason,
  }) async {
    final activeScope = scope;
    if (activeScope == null) return AttendanceMutationResult.failure;
    if (state.reviewingIds.contains(attendanceId)) {
      return AttendanceMutationResult.busy;
    }
    final normalizedReason = rejectionReason?.trim();
    final validation = validateAttendanceReview(decision, normalizedReason);
    if (validation != null) {
      emit(state.copyWith(failure: validation));
      return AttendanceMutationResult.failure;
    }
    final gen = generation;
    emit(
      state.copyWith(
        reviewingIds: {...state.reviewingIds, attendanceId},
        clearFailure: true,
      ),
    );
    try {
      final record = await repository.reviewAttendance(
        activeScope.workspaceId,
        attendanceId,
        decision,
        rejectionReason: normalizedReason,
      );
      if (!isScopeCurrent(activeScope, gen)) {
        return AttendanceMutationResult.stale;
      }
      if (isInvalidReviewedRecord(
        record,
        activeScope.workspaceId,
        attendanceId,
      )) {
        const failure = Failure(
          message: 'The server returned an invalid review response.',
          kind: FailureKind.server,
        );
        emit(
          applyAttendanceReviewResult(state, attendanceId, failure: failure),
        );
        return AttendanceMutationResult.failure;
      }
      emit(applyAttendanceReviewResult(state, attendanceId, record: record));
      onDashboardChanged?.call();
      return AttendanceMutationResult.success;
    } catch (error) {
      if (!isScopeCurrent(activeScope, gen)) {
        return AttendanceMutationResult.stale;
      }
      final failure = attendanceFailure(error, 'Unable to review attendance.');
      emit(applyAttendanceReviewResult(state, attendanceId, failure: failure));
      return AttendanceMutationResult.failure;
    }
  }
}
