import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/entities/attendance_calendar_month.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_month_controls_sections.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';

class AttendanceMonthControls extends StatelessWidget {
  const AttendanceMonthControls({required this.month, super.key});
  final AttendanceCalendarMonth month;

  @override
  Widget build(BuildContext context) {
    final control = month.control;
    if (control == null) return const SizedBox.shrink();
    final membership = context
        .watch<SessionCoordinator?>()
        ?.state
        .activeMembership;
    final manager = membership?.role == WorkspaceRole.manager;
    final busy =
        control.pending +
        control.open +
        control.pendingCorrections +
        control.unfinishedShifts;
    final now = WorkspaceTime.inWorkspace(
      DateTime.now().toUtc(),
      month.timezone,
    );
    final ended = DateTime(
      month.year,
      month.month + 1,
    ).isBefore(DateTime(now.year, now.month, now.day + 1));
    String hours(int m) => context.tr('{hours}h {minutes}m', {
      'hours': '${m ~/ 60}',
      'minutes': '${m % 60}',
    });
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr(
                control.closed
                    ? 'Month approved and closed'
                    : 'Monthly attendance review',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (manager)
              Text(
                context.tr(
                  'Present {present} · Late {late} · Absent {absent} · Leave {leave}',
                  {
                    'present': '${control.present}',
                    'late': '${control.late}',
                    'absent': '${control.absent}',
                    'leave': '${control.leave}',
                  },
                ),
              ),
            Text(
              '${context.tr('Credited work')}: ${hours(control.workMinutes)}',
            ),
            Text(
              '${context.tr('Overtime')}: ${hours(control.overtimeMinutes)}',
            ),
            if (control.closedAt != null)
              Text(WorkspaceTime.dateTime(control.closedAt!, month.timezone)),
            if (manager)
              ...buildManagerMonthControlActions(
                context: context,
                month: month,
                control: control,
                workspaceId: membership!.workspace.id,
                busy: busy,
                ended: ended,
              ),
            if (control.events.isNotEmpty)
              buildAttendanceMonthEventsTile(context, month, control.events),
          ],
        ),
      ),
    );
  }
}
