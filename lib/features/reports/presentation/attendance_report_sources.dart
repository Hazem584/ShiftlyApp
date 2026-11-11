import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/work_duration.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/entities/attendance_record_api.dart';
import 'package:shiftly/features/reports/domain/attendance_report.dart';

class AttendanceSummarySource extends DataTableSource {
  AttendanceSummarySource(this.rows);
  final List<ReportEmployeeRow> rows;
  @override
  DataRow? getRow(int index) {
    if (index >= rows.length) return null;
    final r = rows[index];
    final m = r.metrics;
    return DataRow.byIndex(
      index: index,
      cells: [
        for (final value in [
          r.employee.name,
          m.attendanceDays,
          m.approved,
          m.pending,
          m.rejected,
          m.open,
          m.late,
          m.lateMinutes,
          (m.workMinutes / 60).toStringAsFixed(2),
          (m.extraMinutes / 60).toStringAsFixed(2),
          (m.excessMinutes / 60).toStringAsFixed(2),
        ])
          DataCell(Text('$value')),
      ],
    );
  }

  @override
  int get rowCount => rows.length;
  @override
  bool get isRowCountApproximate => false;
  @override
  int get selectedRowCount => 0;
}

class AttendanceDetailsSource extends DataTableSource {
  AttendanceDetailsSource(this.report, String? employeeId, this.strings)
    : rows = report.recordsFor(employeeId);
  final AttendanceReport report;
  final AppLocalizations strings;
  final List<AttendanceRecordApi> rows;
  @override
  DataRow? getRow(int index) {
    if (index >= rows.length) return null;
    final r = rows[index];
    return DataRow.byIndex(
      index: index,
      cells: [
        for (final value in [
          r.employee.displayName,
          WorkspaceTime.dateTime(r.clockInAt, report.timezone),
          r.clockOutAt == null
              ? strings.text('Not recorded')
              : WorkspaceTime.dateTime(r.clockOutAt!, report.timezone),
          strings.text(
            r.reviewStatus.name[0].toUpperCase() +
                r.reviewStatus.name.substring(1),
          ),
          r.minutesLate,
          r.workedMinutes == null
              ? strings.text('Not recorded')
              : workDurationWithOvertime(
                  r.netWorkedMinutes ?? r.workedMinutes!,
                  r.overtimeMinutes,
                  arabic: strings.locale.languageCode == 'ar',
                ),
        ])
          DataCell(Text('$value')),
      ],
    );
  }

  @override
  int get rowCount => rows.length;
  @override
  bool get isRowCountApproximate => false;
  @override
  int get selectedRowCount => 0;
}
