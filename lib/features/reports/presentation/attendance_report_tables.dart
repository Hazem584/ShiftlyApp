import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/reports/domain/attendance_report.dart';
import 'package:shiftly/features/reports/presentation/attendance_report_sources.dart';

const _notes = [
  'Hours include approved closed records only. Open, pending and rejected records do not add hours.',
  'Overtime includes time after the shift, minus arrival delay. Unused break time is added at shift end for on-time attendance.',
  'Dates use clock-in time in the workspace timezone. Overnight work stays on the clock-in date. Recorded breaks are deducted.',
  'Attendance days count distinct approved clock-in dates per employee. No attendance does not prove absence.',
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
}) => [
  const SizedBox(height: 12),
  for (final note in _notes) Text(context.tr(note)),
  const SizedBox(height: 16),
  if (report.recordsFor(employeeId).isEmpty)
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(context.tr('No attendance in this period.')),
    ),
  if (report.rowsFor(employeeId).isNotEmpty)
    PaginatedDataTable(
      key: ValueKey('summary-${report.generatedAt}-$employeeId'),
      header: Text(context.tr('Employee summary')),
      rowsPerPage: 10,
      availableRowsPerPage: const [10],
      showFirstLastButtons: true,
      columnSpacing: 20,
      columns: [
        for (final t in _summaryColumns) DataColumn(label: Text(context.tr(t))),
      ],
      source: AttendanceSummarySource(report.rowsFor(employeeId)),
    ),
  if (report.recordsFor(employeeId).isNotEmpty) ...[
    const SizedBox(height: 16),
    PaginatedDataTable(
      key: ValueKey('details-${report.generatedAt}-$employeeId'),
      header: Text(context.tr('Attendance details')),
      rowsPerPage: 10,
      availableRowsPerPage: const [10],
      showFirstLastButtons: true,
      columnSpacing: 20,
      columns: [
        for (final t in _detailColumns) DataColumn(label: Text(context.tr(t))),
      ],
      source: AttendanceDetailsSource(
        report,
        employeeId,
        AppLocalizations.of(context),
      ),
    ),
  ],
];
