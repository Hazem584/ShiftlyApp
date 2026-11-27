import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_state.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

Failure attendanceFailure(Object error, String fallback) =>
    error is ApiException ? error.toFailure() : Failure(message: fallback);

Failure? validateAttendanceReview(
  AttendanceReviewDecision decision,
  String? normalizedReason,
) {
  if (decision == AttendanceReviewDecision.rejected &&
      (normalizedReason == null || normalizedReason.isEmpty)) {
    return const Failure(
      message: 'A rejection reason is required.',
      kind: FailureKind.validation,
    );
  }
  if ((normalizedReason?.length ?? 0) > 1000) {
    return const Failure(
      message: 'Rejection reason is too long.',
      kind: FailureKind.validation,
    );
  }
  return null;
}

bool isInvalidReviewedRecord(
  AttendanceRecordApi record,
  String workspaceId,
  String attendanceId,
) =>
    record.workspaceId != workspaceId ||
    record.id != attendanceId ||
    record.reviewStatus == AttendanceReviewStatus.pending ||
    record.reviewStatus == AttendanceReviewStatus.unknown;

ManagerAttendanceState applyAttendanceReviewResult(
  ManagerAttendanceState state,
  String attendanceId, {
  AttendanceRecordApi? record,
  Failure? failure,
}) {
  final reviewing = {...state.reviewingIds}..remove(attendanceId);
  return state.copyWith(
    reviewingIds: reviewing,
    records: record == null
        ? state.records
        : state.records
              .map((item) => item.id == attendanceId ? record : item)
              .toList(growable: false),
    pending: record == null
        ? state.pending
        : state.pending
              .where((item) => item.id != attendanceId)
              .toList(growable: false),
    selected: record ?? state.selected,
    failure: failure,
  );
}
