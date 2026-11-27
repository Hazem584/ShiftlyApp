import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/work_duration.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/breaks/application/shift_break_controller.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/flexible_attendance.dart';

import 'employee_tile.dart';

class EmployeeBreakPanelContent extends StatelessWidget {
  const EmployeeBreakPanelContent({
    required this.breaks,
    required this.attendance,
    required this.timezone,
    required this.enabled,
    required this.onToggle,
    super.key,
  });

  final ShiftBreakController breaks;
  final FlexibleAttendance attendance;
  final String timezone;
  final bool enabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final running = breaks.running;
    final remaining = breaks.remaining;
    final locale = Localizations.localeOf(context);
    final arabic = locale.languageCode == 'ar';
    final deduction = attendance.breakState?.lateDeductionMinutes ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EmployeeTile(
          icon: Icons.coffee_outlined,
          title: context.tr(running ? 'Break timer' : 'A moment to recharge'),
          subtitle: running
              ? '${remaining.inMinutes.toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')} · ${context.tr('remaining')}'
              : context.tr('Available break: {duration}', {
                  'duration': workDuration(
                    breaks.availableSeconds ~/ 60,
                    arabic: arabic,
                  ),
                }),
          onTap: enabled && !breaks.busy && (running || breaks.canStart)
              ? onToggle
              : null,
        ),
        const SizedBox(height: 12),
        if (running || breaks.canStart)
          OutlinedButton(
            key: const Key('employee-break-action'),
            onPressed: !enabled || breaks.busy ? null : onToggle,
            child: Text(context.tr(running ? 'End break' : 'Start break')),
          ),
        if (breaks.reminderAt != null && !running)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              context.tr('Break at {time}', {
                'time': WorkspaceTime.time(
                  breaks.reminderAt!,
                  timezone,
                  locale: locale.toString(),
                ),
              }),
            ),
          ),
        if (deduction > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              context.tr('Break reduced by {time} for late arrival.', {
                'time': workDuration(deduction, arabic: arabic),
              }),
            ),
          ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            context.tr(
              'Breaks are recorded against your allowance. Unused break and overtime follow your workspace attendance rules.',
            ),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        if (running && !breaks.notificationScheduled)
          Text(
            context.tr(
              'Timer is running. Enable notifications to receive a background alert.',
            ),
          ),
        if (breaks.error != null)
          Text(
            context.tr(breaks.error!),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }
}
