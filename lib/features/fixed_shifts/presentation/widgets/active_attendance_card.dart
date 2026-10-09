import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/utils/workspace_time.dart';

import '../../data/fixed_shift_repository.dart';
import 'attendance_presentation.dart';

import 'package:shiftly/core/widgets/surface_card.dart';

class ActiveAttendanceCard extends StatelessWidget {
  const ActiveAttendanceCard({
    super.key,
    required this.attendance,
    required this.timezone,
    required this.busy,
    required this.onClockOut,
  });
  final FlexibleAttendance attendance;
  final String timezone;
  final bool busy;
  final VoidCallback onClockOut;
  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 48,
              decoration: BoxDecoration(
                color: attendanceTemplateColor(
                  attendance.templateColor ?? '#334155',
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active attendance',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    attendance.templateName ?? 'Fixed shift',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const Icon(Icons.radio_button_checked, color: AppColors.success),
          ],
        ),
        Text(
          attendance.occurrenceKind == 'EXTRA'
              ? 'Authorized EXTRA ? no automatic BLUE award'
              : attendance.occurrenceKind == 'BASELINE'
              ? 'Assigned BASELINE'
              : 'Historical attendance ? assignment evidence not recorded',
        ),
        const SizedBox(height: 12),
        Text(
          'Clocked in: ${WorkspaceTime.dateTime(attendance.clockInAt, attendance.workspaceTimezone ?? timezone, locale: Localizations.localeOf(context).toString())}',
        ),
        if (attendance.scheduledStartAt != null &&
            attendance.scheduledEndAt != null)
          Text(
            'Schedule: ${WorkspaceTime.time(attendance.scheduledStartAt, attendance.workspaceTimezone ?? timezone, locale: Localizations.localeOf(context).toString())} – ${WorkspaceTime.time(attendance.scheduledEndAt, attendance.workspaceTimezone ?? timezone, locale: Localizations.localeOf(context).toString())}',
          ),
        Text(
          'Operational date: ${attendance.operationalDate ?? 'Unavailable'}',
        ),
        Text(
          '${attendanceClassificationLabel(attendance.classification ?? AttendanceClassification.unknown)}${attendance.minutesLate > 0 ? ' • ${attendance.minutesLate} min late' : ''}',
        ),
        const SizedBox(height: 6),
        StreamBuilder<int>(
          stream: Stream<int>.periodic(
            const Duration(minutes: 1),
            (value) => value,
          ),
          builder: (_, _) => Text(
            'Elapsed (display only): ${attendanceElapsed(DateTime.now().toUtc().difference(attendance.clockInAt))}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: busy ? null : onClockOut,
            icon: busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded),
            label: const Text('Clock out'),
          ),
        ),
      ],
    ),
  );
}
