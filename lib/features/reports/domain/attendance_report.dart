import 'package:shiftly/features/attendance/domain/entities/attendance_record_api.dart';
import 'package:shiftly/features/reports/domain/report_metrics.dart';
import 'package:shiftly/features/reports/domain/report_metrics_calculator.dart';
import 'package:shiftly/features/reports/domain/report_range.dart';

export 'package:shiftly/features/reports/domain/report_metrics.dart';
export 'package:shiftly/features/reports/domain/report_range.dart';

class AttendanceReport {
  AttendanceReport({
    required this.workspaceId,
    required this.workspaceName,
    required this.timezone,
    required this.range,
    required this.generatedAt,
    required List<ReportEmployee> employees,
    required List<AttendanceRecordApi> records,
    this.payrollDays,
  }) : employees = List.unmodifiable(employees),
       records = List.unmodifiable(records);

  final String workspaceId, workspaceName, timezone;
  final ReportRange range;
  final DateTime generatedAt;
  final List<ReportEmployee> employees;
  final List<AttendanceRecordApi> records;
  final Map<String, ({int absent, int leave})>? payrollDays;

  List<AttendanceRecordApi> recordsFor(String? employeeId) => records
      .where((r) => employeeId == null || r.employeeMembershipId == employeeId)
      .toList(growable: false);

  List<ReportEmployeeRow> rowsFor(String? employeeId) => employees
      .where((e) => employeeId == null || e.id == employeeId)
      .map(
        (e) => ReportEmployeeRow(
          e,
          _employeeMetrics[e.id] ?? const ReportMetrics(),
          payrollDays: payrollDays == null
              ? null
              : payrollDays![e.id] ?? (absent: 0, leave: 0),
          fullMonth:
              range.start.day == 1 &&
              range.end ==
                  DateTime.utc(range.start.year, range.start.month + 1, 0),
        ),
      )
      .toList(growable: false);

  late final Map<String, ReportMetrics> _employeeMetrics = _buildMetrics();

  Map<String, ReportMetrics> _buildMetrics() {
    final grouped = <String, List<AttendanceRecordApi>>{};
    for (final r in records) {
      grouped.putIfAbsent(r.employeeMembershipId, () => []).add(r);
    }
    return grouped.map(
      (id, values) => MapEntry(id, calculateEmployeeMetrics(values, timezone)),
    );
  }

  ReportMetrics totalsFor(String? employeeId) =>
      rowsFor(employeeId)
          .fold(const ReportMetrics(), (sum, row) => sum + row.metrics);
}

abstract interface class AttendanceReportRepository {
  Future<AttendanceReport> load({
    required String workspaceId,
    required String workspaceName,
    required String timezone,
    required ReportRange range,
    required bool Function() isCurrent,
  });
}
