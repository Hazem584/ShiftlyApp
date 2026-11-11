import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/reports/domain/attendance_report.dart';

class AttendanceReportTotals extends StatelessWidget {
  const AttendanceReportTotals({required this.metrics, super.key});
  final ReportMetrics metrics;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      for (final item in <(String, String)>[
        ('Employee attendance days', '${metrics.attendanceDays}'),
        ('Late records', '${metrics.late}'),
        ('Late minutes', '${metrics.lateMinutes}'),
        ('Worked hours', (metrics.workMinutes / 60).toStringAsFixed(2)),
        ('Extra shift hours', (metrics.extraMinutes / 60).toStringAsFixed(2)),
        (
          'Schedule excess hours',
          (metrics.excessMinutes / 60).toStringAsFixed(2),
        ),
        ('Pending records', '${metrics.pending}'),
        ('Rejected records', '${metrics.rejected}'),
        ('Open records', '${metrics.open}'),
        if (metrics.missingSchedule > 0)
          ('Missing schedule', '${metrics.missingSchedule}'),
        if (metrics.missingWorkMinutes > 0)
          ('Missing work duration', '${metrics.missingWorkMinutes}'),
        if (metrics.unknown > 0)
          ('Unknown review status', '${metrics.unknown}'),
      ])
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr(item.$1)),
                Text(item.$2, style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
          ),
        ),
    ],
  );
}
