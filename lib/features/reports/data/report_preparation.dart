import 'package:flutter/foundation.dart';
import 'package:shiftly/features/attendance/domain/entities/attendance_record_api.dart';
import 'package:shiftly/features/reports/domain/attendance_report.dart';

class ReportPreparation {
  const ReportPreparation({
    required this.workspaceId,
    required this.workspaceName,
    required this.timezone,
    required this.range,
    required this.generatedAt,
    required this.employees,
    required this.records,
  });
  final String workspaceId, workspaceName, timezone;
  final ReportRange range;
  final DateTime generatedAt;
  final List<ReportEmployee> employees;
  final List<AttendanceRecordApi> records;
}

Future<AttendanceReport> prepareAttendanceReport(ReportPreparation input) =>
    input.records.length >= 200 || input.employees.length >= 200
    ? compute(
        buildAttendanceReport,
        input,
        debugLabel: 'shiftly.report.prepare',
      )
    : Future.value(buildAttendanceReport(input));

/// Prepares historical membership rows, sorting and per-employee metrics before
/// the UI receives the report. Timezone data initializes inside this worker.
AttendanceReport buildAttendanceReport(ReportPreparation input) {
  final employees = {for (final e in input.employees) e.id: e};
  for (final record in input.records) {
    employees.putIfAbsent(
      record.employeeMembershipId,
      () => ReportEmployee(
        record.employeeMembershipId,
        record.employee.displayName,
      ),
    );
  }
  final sorted = employees.values.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  final records = List<AttendanceRecordApi>.of(input.records)
    ..sort((a, b) => a.clockInAt.compareTo(b.clockInAt));
  final report = AttendanceReport(
    workspaceId: input.workspaceId,
    workspaceName: input.workspaceName,
    timezone: input.timezone,
    range: input.range,
    generatedAt: input.generatedAt,
    employees: sorted,
    records: records,
  );
  // Populate the report's lazy metric cache in the worker, not during rendering.
  report.totalsFor(null);
  return report;
}
