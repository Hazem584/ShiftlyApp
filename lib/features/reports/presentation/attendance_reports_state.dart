import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/reports/domain/attendance_report.dart';

class AttendanceReportsState {
  const AttendanceReportsState({
    this.range,
    this.period = ReportPeriod.monthly,
    this.report,
    this.employeeId,
    this.loading = false,
    this.failure,
  });

  final ReportRange? range;
  final ReportPeriod period;
  final AttendanceReport? report;
  final String? employeeId;
  final bool loading;
  final Failure? failure;

  AttendanceReportsState copyWithEmployee(String? id) => AttendanceReportsState(
    range: range,
    period: period,
    report: report,
    employeeId: id,
  );

  AttendanceReportsState invalidated() => AttendanceReportsState(
    range: range,
    period: period,
    employeeId: employeeId,
    failure: const Failure(message: 'Attendance changed. Refresh the report.'),
  );
}

void validateAttendanceReportScope(
  AttendanceReport r,
  FeatureSessionScope s,
  ReportRange range,
) {
  if (r.workspaceId != s.workspaceId ||
      r.timezone != s.timezone ||
      r.range.startKey != range.startKey ||
      r.range.endKey != range.endKey) {
    throw const FormatException('Invalid report scope');
  }
}
