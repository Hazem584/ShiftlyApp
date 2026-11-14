import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/work_duration.dart';
import 'package:shiftly/features/reports/domain/attendance_report.dart';

class ManagerReportOverview extends StatelessWidget {
  const ManagerReportOverview({required this.metrics, super.key});
  final ReportMetrics metrics;
  @override
  Widget build(BuildContext context) {
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in [
          (
            Icons.calendar_today_outlined,
            context.tr('{count} attendance days', {
              'count': '${metrics.attendanceDays}',
            }),
            context.tr(
              '{approved} approved · {pending} pending · {rejected} rejected',
              {
                'approved': '${metrics.approved}',
                'pending': '${metrics.pending}',
                'rejected': '${metrics.rejected}',
              },
            ),
          ),
          (
            Icons.schedule_outlined,
            context.tr('{duration} worked', {
              'duration': workDuration(metrics.workMinutes, arabic: arabic),
            }),
            context.tr('Extra work: {duration}', {
              'duration': workDuration(
                metrics.extraMinutes + metrics.excessMinutes,
                arabic: arabic,
              ),
            }),
          ),
          (
            Icons.access_time,
            context.tr('Lateness'),
            context.tr('{count} late arrivals · {duration} total', {
              'count': '${metrics.late}',
              'duration': workDuration(metrics.lateMinutes, arabic: arabic),
            }),
          ),
        ]) ...[
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Icon(item.$1),
              title: Text(item.$2),
              subtitle: Text(item.$3),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (metrics.open > 0)
          Text(
            context.tr('{count} open records', {'count': '${metrics.open}'}),
          ),
        if (metrics.missingSchedule +
                metrics.missingWorkMinutes +
                metrics.unknown >
            0)
          Text(
            context.tr(
              'Some records need review before their hours can be counted.',
            ),
          ),
      ],
    );
  }
}
