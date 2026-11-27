import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_calendar_repository.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';

String? validateCompletedAttendancePeriod(DateTime start, DateTime end) {
  final duration = end.difference(start);
  if (duration.inMinutes < 1 ||
      duration > const Duration(hours: 24) ||
      end.isAfter(DateTime.now())) {
    return 'Choose a completed period of up to 24 hours, ending before now.';
  }
  return null;
}

Future<void> submitAttendanceDayEdit({
  required TeamWorkRepository repository,
  required String workspaceId,
  required bool manager,
  required AttendanceCalendarEntry entry,
  required DateTime date,
  required String reasonKind,
  required DateTime start,
  required DateTime end,
  required String reason,
}) async {
  final shift = entry.shift;
  final dateKey = WorkspaceTime.localDateKey(
    year: date.year,
    month: date.month,
    day: date.day,
  );
  final legacyId =
      shift != null &&
          shift.assignmentId == null &&
          shift.extraAuthorizationId == null
      ? shift.id
      : null;
  if (manager) {
    final cleanReason = reason.trim().length >= 5
        ? reason.trim()
        : 'Updated by manager';
    await repository.recordAttendanceDay(
      workspaceId,
      employeeMembershipId: entry.employeeMembershipId,
      attendanceId: entry.attendance?.id,
      assignmentId: shift?.assignmentId,
      extraAuthorizationId: shift?.extraAuthorizationId,
      shiftId: legacyId,
      operationalDate: dateKey,
      reasonKind: reasonKind,
      clockIn: start,
      clockOut: end,
      reason: cleanReason,
    );
  } else if (entry.attendance != null) {
    await repository.requestCorrection(
      workspaceId,
      attendanceId: entry.attendance!.id,
      clockIn: start,
      clockOut: end,
      reason: reason,
    );
  } else {
    await repository.requestMissedAttendance(
      workspaceId,
      assignmentId: shift?.assignmentId,
      extraAuthorizationId: shift?.extraAuthorizationId,
      shiftId: legacyId,
      operationalDate: dateKey,
      reasonKind: reasonKind,
      clockIn: start,
      clockOut: end,
      reason: reason,
    );
  }
}
