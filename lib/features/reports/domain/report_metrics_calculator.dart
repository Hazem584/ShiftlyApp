import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/entities/attendance_record_api.dart';
import 'package:shiftly/features/attendance/domain/services/attendance_overtime.dart';
import 'package:shiftly/features/reports/domain/report_metrics.dart';
import 'package:shiftly/features/shifts/domain/entities/attendance_review_status.dart';

ReportMetrics calculateEmployeeMetrics(
  List<AttendanceRecordApi> values,
  String timezone,
) {
  var result = const ReportMetrics();
  final days = <String>{}, absent = <String>{}, leave = <String>{};
  for (final r in values) {
    final day =
        r.operationalDate?.split('T').first ??
        WorkspaceTime.dateKey(r.clockInAt, timezone);
    if (r.dayStatus == 'ABSENT') {
      absent.add(day);
      continue;
    }
    if (r.dayStatus == 'LEAVE') {
      leave.add(day);
      continue;
    }
    switch (r.reviewStatus) {
      case AttendanceReviewStatus.pending:
        result += const ReportMetrics(pending: 1);
      case AttendanceReviewStatus.rejected:
        result += const ReportMetrics(rejected: 1);
      case AttendanceReviewStatus.unknown:
        result += const ReportMetrics(unknown: 1);
      case AttendanceReviewStatus.approved:
        days.add(day);
        result += _approvedRecordMetrics(r);
    }
  }
  return result +
      ReportMetrics(
        attendanceDays: days.length,
        absentDays: absent.difference(days).difference(leave).length,
        paidLeaveDays: leave.difference(days).length,
      );
}

ReportMetrics _approvedRecordMetrics(AttendanceRecordApi r) {
  final closed = r.clockOutAt != null;
  final work = closed ? r.netWorkedMinutes ?? r.workedMinutes ?? 0 : 0;
  final extra = r.occurrenceKind == 'EXTRA';
  final start = r.scheduledStartAt ?? r.shift?.startsAt;
  final end = r.scheduledEndAt ?? r.shift?.endsAt;
  final scheduled = start != null && end != null
      ? end.difference(start).inMinutes
      : null;
  final earlyLeave =
      closed && !extra && end != null && r.clockOutAt!.isBefore(end)
      ? end.difference(r.clockOutAt!).inMinutes.clamp(0, 720)
      : 0;
  return ReportMetrics(
    approved: 1,
    open: closed ? 0 : 1,
    late: r.dayStatus == 'LATE' || (r.dayStatus == null && r.minutesLate > 0)
        ? 1
        : 0,
    lateMinutes: r.dayStatus == 'PRESENT' ? 0 : r.minutesLate,
    earlyLeaveMinutes: earlyLeave,
    workMinutes: work,
    extraMinutes: extra ? work : 0,
    excessMinutes: !extra && closed
        ? r.netWorkedMinutes != null
              ? r.overtimeMinutes
              : attendanceOvertimeMinutes(
                  clockIn: r.clockInAt,
                  clockOut: r.clockOutAt!,
                  scheduledStart: start,
                  scheduledEnd: end,
                )
        : 0,
    missingSchedule: closed && !extra && (scheduled == null || scheduled <= 0)
        ? 1
        : 0,
    missingWorkMinutes: closed && r.workedMinutes == null ? 1 : 0,
  );
}
