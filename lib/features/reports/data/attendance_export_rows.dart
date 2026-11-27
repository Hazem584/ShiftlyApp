import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/reports/domain/attendance_report.dart';
import 'package:shiftly/features/reports/domain/report_export.dart';
import 'package:shiftly/features/shifts/domain/entities/attendance_review_status.dart';

List<List<Object>> buildExportDetailRows(
  AttendanceReport report,
  String? employeeId,
  ReportLabels strings,
) => report
    .recordsFor(employeeId)
    .map(
      (r) => <Object>[
        r.employee.displayName,
        r.id,
        WorkspaceTime.dateTime(r.clockInAt, report.timezone),
        r.clockOutAt == null
            ? strings.text('Not recorded')
            : WorkspaceTime.dateTime(r.clockOutAt!, report.timezone),
        strings.text(switch (r.reviewStatus) {
          AttendanceReviewStatus.approved => 'Approved',
          AttendanceReviewStatus.pending => 'Pending',
          AttendanceReviewStatus.rejected => 'Rejected',
          AttendanceReviewStatus.unknown => 'Unknown',
        }),
        strings.text(
          r.occurrenceKind == 'EXTRA' ? 'Extra shift' : 'Regular shift',
        ),
        r.minutesLate,
        r.netWorkedMinutes ?? r.workedMinutes ?? '',
        '${r.templateName ?? ''} · ${r.operationalDate ?? ''}\n'
            '${r.scheduledStartAt == null ? '' : WorkspaceTime.dateTime(r.scheduledStartAt!, r.workspaceTimezone ?? report.timezone)} - '
            '${r.scheduledEndAt == null ? '' : WorkspaceTime.dateTime(r.scheduledEndAt!, r.workspaceTimezone ?? report.timezone)}',
        r.scheduleExceptionReason ?? '',
      ],
    )
    .toList();

List<List<Object>> buildExportMetadataRows(
  AttendanceReport r,
  String? employeeId,
  ReportLabels s,
) {
  final rows = r.rowsFor(employeeId);
  final selected = employeeId == null
      ? s.text('All employees')
      : rows.first.employee.name;
  final t = r.totalsFor(employeeId);
  return [
    [s.text('Workspace'), r.workspaceName],
    [s.text('Period'), r.range.label],
    [s.text('Employee filter'), selected],
    [s.text('Timezone'), r.timezone],
    [s.text('Generated at'), WorkspaceTime.dateTime(r.generatedAt, r.timezone)],
    [
      s.text(
        'Hours include approved closed records only. Open, pending and rejected records do not add hours.',
      ),
    ],
    [
      s.text(
        'Overtime includes time after the shift, minus arrival delay. Unused break time is added at shift end for on-time attendance.',
      ),
    ],
    [
      s.text(
        'Dates use clock-in time in the workspace timezone. Overnight work stays on the clock-in date. Recorded breaks are deducted.',
      ),
    ],
    [
      s.text(
        'Attendance days count distinct approved clock-in dates per employee. No attendance does not prove absence.',
      ),
    ],
    ['${s.text('Missing schedule')}: ${t.missingSchedule}'],
    ['${s.text('Missing work duration')}: ${t.missingWorkMinutes}'],
    ['${s.text('Unknown review status')}: ${t.unknown}'],
  ];
}
