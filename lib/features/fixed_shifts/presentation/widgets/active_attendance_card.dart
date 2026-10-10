import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/attendance_presentation.dart';

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
                  Text(
                    context.tr('Active attendance'),
                    style: TextStyle(
                      color: AppPalette.of(context).success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    attendance.templateName ?? context.tr('Fixed shift'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.radio_button_checked,
              color: AppPalette.of(context).success,
            ),
          ],
        ),
        Text(
          context.tr(
            attendance.occurrenceKind == 'EXTRA'
                ? 'Authorized EXTRA ? no automatic BLUE award'
                : attendance.occurrenceKind == 'BASELINE'
                ? 'Assigned BASELINE'
                : 'Historical attendance ? assignment evidence not recorded',
          ),
        ),
        const SizedBox(height: 12),
        Text(
          context.tr('Clocked in: {time}', {
            'time': WorkspaceTime.dateTime(
              attendance.clockInAt,
              attendance.workspaceTimezone ?? timezone,
              locale: Localizations.localeOf(context).toString(),
            ),
          }),
        ),
        if (attendance.scheduledStartAt != null &&
            attendance.scheduledEndAt != null)
          Text(
            context.tr('Schedule: {start} – {end}', {
              'start': WorkspaceTime.time(
                attendance.scheduledStartAt,
                attendance.workspaceTimezone ?? timezone,
                locale: Localizations.localeOf(context).toString(),
              ),
              'end': WorkspaceTime.time(
                attendance.scheduledEndAt,
                attendance.workspaceTimezone ?? timezone,
                locale: Localizations.localeOf(context).toString(),
              ),
            }),
          ),
        Text(
          context.tr('Operational date: {date}', {
            'date': attendance.operationalDate ?? context.tr('Unavailable'),
          }),
        ),
        Text(
          context.tr('{value1}{value2}', {
            'value1': (context.tr(
              attendanceClassificationLabel(
                attendance.classification ?? AttendanceClassification.unknown,
              ),
            )).toString(),
            'value2':
                (attendance.minutesLate > 0
                        ? ' • ${context.tr('{minutes} min late', {'minutes': '${attendance.minutesLate}'})}'
                        : '')
                    .toString(),
          }),
        ),
        const SizedBox(height: 6),
        Text(
          context.tr(
            'Use Clock out when you finish. Your workspace confirms the final worked duration.',
          ),
        ),
        StreamBuilder<int>(
          stream: Stream<int>.periodic(
            const Duration(minutes: 1),
            (value) => value,
          ),
          builder: (_, _) => Text(
            context.tr('Elapsed (display only): {duration}', {
              'duration': attendanceElapsed(
                DateTime.now().toUtc().difference(attendance.clockInAt),
                context,
              ),
            }),
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
            label: Text(context.tr('Clock out')),
          ),
        ),
      ],
    ),
  );
}
