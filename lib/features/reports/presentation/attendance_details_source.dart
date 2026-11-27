import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/work_duration.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/entities/attendance_record_api.dart';
import 'package:shiftly/features/reports/domain/attendance_report.dart';

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
    final statusName = r.reviewStatus.name;
    return DataRow.byIndex(
      index: index,
      cells: [
        for (final value in [
          r.employee.displayName,
          WorkspaceTime.dateTime(r.clockInAt, report.timezone),
          r.clockOutAt == null
              ? strings.text('Not recorded')
              : WorkspaceTime.dateTime(r.clockOutAt!, report.timezone),
          strings.text(statusName[0].toUpperCase() + statusName.substring(1)),
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
