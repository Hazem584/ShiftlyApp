import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';

class ManagerAttendanceRecordTile extends StatelessWidget {
  const ManagerAttendanceRecordTile({
    required this.record,
    required this.timezone,
    this.onTap,
    this.trailing,
    super.key,
  });
  final AttendanceRecordApi record;
  final String timezone;
  final VoidCallback? onTap;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final zone = record.workspaceTimezone ?? timezone;
    final locale = Localizations.localeOf(context).toString();
    final day =
        record.operationalDate ??
        WorkspaceTime.dateTime(record.clockInAt, zone, locale: locale);
    return SurfaceCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.schedule_outlined),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  record.employee.displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${record.templateName ?? context.tr('Attendance record')} · $day',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            '${WorkspaceTime.time(record.clockInAt, zone, locale: locale)} – ${WorkspaceTime.time(record.clockOutAt, zone, locale: locale)}',
            textDirection: TextDirection.ltr,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                context.tr(switch (record.reviewStatus.name) {
                  'approved' => 'Approved',
                  'pending' => 'Pending review',
                  'rejected' => 'Rejected',
                  _ => 'Unavailable',
                }),
              ),
              Text(
                record.isOpen
                    ? context.tr('Open attendance')
                    : record.workedMinutes == null
                    ? context.tr('Duration not recorded')
                    : context.tr('{value1} minutes worked', {
                        'value1': record.workedMinutes.toString(),
                      }),
              ),
              Text(
                context.tr('{count} minutes late', {
                  'count': record.minutesLate.toString(),
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(zone, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
