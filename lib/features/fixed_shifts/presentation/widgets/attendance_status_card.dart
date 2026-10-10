import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/flexible_attendance_state.dart';
import 'package:shiftly/features/fixed_shifts/presentation/models/attendance_status_summary.dart';

class AttendanceStatusCard extends StatelessWidget {
  const AttendanceStatusCard({
    required this.state,
    required this.timezone,
    this.onOpenShifts,
    super.key,
  });

  final FlexibleAttendanceState state;
  final String timezone;
  final VoidCallback? onOpenShifts;

  @override
  Widget build(BuildContext context) {
    final summary = AttendanceStatusSummary.fromState(
      state,
      actionLocation: context.tr(
        onOpenShifts == null ? 'below' : 'in My Shifts',
      ),
    );
    final colors = Theme.of(context).colorScheme;
    final color = switch (summary.tone) {
      AttendanceStatusTone.active ||
      AttendanceStatusTone.ready => colors.primary,
      AttendanceStatusTone.attention => colors.error,
      AttendanceStatusTone.neutral => colors.onSurfaceVariant,
    };
    final entry = summary.occurrence;
    final locale = Localizations.localeOf(context).toString();
    final savedTimezone =
        entry?.timezone ?? state.current?.workspaceTimezone ?? timezone;
    return Semantics(
      liveRegion: true,
      child: SurfaceCard(
        key: const Key('attendance-status-card'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  summary.tone == AttendanceStatusTone.attention
                      ? Icons.info_outline_rounded
                      : Icons.schedule_rounded,
                  color: color,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr(summary.title),
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(context.tr(summary.message, summary.arguments)),
            if (entry != null) ...[
              const SizedBox(height: 10),
              Text(
                context.tr('{value1} – {value2}', {
                  'value1': (WorkspaceTime.time(
                    entry.scheduledStartAt,
                    savedTimezone,
                    locale: locale,
                  )).toString(),
                  'value2': (WorkspaceTime.time(
                    entry.scheduledEndAt,
                    savedTimezone,
                    locale: locale,
                  )).toString(),
                }),
              ),
              Text(
                context.tr('Shift date: {date}', {
                  'date': entry.operationalDate,
                }),
              ),
              Text(
                context.tr('Check-in opens: {time}', {
                  'time': WorkspaceTime.dateTime(
                    entry.checkInWindowStart,
                    savedTimezone,
                    locale: locale,
                  ),
                }),
              ),
            ],
            if (state.eligibility != null) ...[
              const SizedBox(height: 8),
              Text(
                context.tr('Last checked: {time}', {
                  'time': WorkspaceTime.dateTime(
                    state.eligibility!.evaluatedAt,
                    state.eligibility!.timezone,
                    locale: locale,
                  ),
                }),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (onOpenShifts != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onOpenShifts,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(context.tr('Open My Shifts')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
