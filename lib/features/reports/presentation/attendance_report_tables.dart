import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/reports/domain/attendance_report.dart';
import 'package:shiftly/features/reports/presentation/attendance_report_sources.dart';

const _notes = [
  'Hours include approved closed records only. Open, pending and rejected records do not add hours.',
  'Overtime includes time after the shift, minus arrival delay. Unused break time is added at shift end for on-time attendance.',
  'Dates use clock-in time in the workspace timezone. Overnight work stays on the clock-in date. Recorded breaks are deducted.',
  'Attendance days count distinct approved clock-in dates per employee. No attendance does not prove absence.',
  'Monthly payroll deducts scheduled absences at the daily rate. Approved leave is paid.',
  'Partial periods show pay for attendance and paid leave in the selected dates.',
];

const _summaryColumns = [
  'Employee',
  'Attendance days',
  'Approved records',
  'Pending records',
  'Rejected records',
  'Open records',
  'Late records',
  'Late minutes',
  'Worked hours',
  'Extra shift hours',
  'Schedule excess hours',
  'Hourly rate',
  'Base pay',
  'Deductions',
  'Overtime pay',
  'Net payable',
];

const _detailColumns = [
  'Employee',
  'Clock in',
  'Clock out',
  'Review status',
  'Late minutes',
  'Worked hours',
];

List<Widget> buildReportTablesSection(
  BuildContext context, {
  required AttendanceReport report,
  required String? employeeId,
}) {
  final summarySource = AttendanceSummarySource(report.rowsFor(employeeId));
  final detailsSource = AttendanceDetailsSource(
    report,
    employeeId,
    AppLocalizations.of(context),
  );
  return [
    const SizedBox(height: 12),
    for (final note in _notes) Text(context.tr(note)),
    const SizedBox(height: 16),
    if (detailsSource.rowCount == 0)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(context.tr('No attendance in this period.')),
      ),
    if (summarySource.rowCount > 0)
      _tableCard(
        context,
        key: ValueKey('summary-${report.generatedAt}-$employeeId'),
        title: context.tr('Employee summary'),
        columns: _summaryColumns,
        source: summarySource,
      ),
    if (detailsSource.rowCount > 0) ...[
      const SizedBox(height: 16),
      _tableCard(
        context,
        key: ValueKey('details-${report.generatedAt}-$employeeId'),
        title: context.tr('Attendance details'),
        columns: _detailColumns,
        source: detailsSource,
      ),
    ],
  ];
}

Widget _tableCard(
  BuildContext context, {
  required Key key,
  required String title,
  required List<String> columns,
  required DataTableSource source,
}) => Card(
  key: key,
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 20,
            columns: [
              for (final t in columns) DataColumn(label: Text(context.tr(t))),
            ],
            rows: [
              for (var i = 0; i < source.rowCount; i++) ?source.getRow(i),
            ],
          ),
        ),
      ],
    ),
  ),
);
