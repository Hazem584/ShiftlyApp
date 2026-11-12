import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/entities/attendance_calendar_month.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_controls_repository.dart';
import 'package:shiftly/features/attendance/presentation/refresh_attendance_views.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';

import 'attendance_decision_dialog.dart';

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
            if (manager) ...[
              if (busy > 0)
                Text(
                  context.tr(
                    'Resolve {count} open records and pending reviews before closing.',
                    {'count': '$busy'},
                  ),
                ),
              if (!ended && !control.closed)
                Text(
                  context.tr(
                    'Month approval becomes available after the month ends.',
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: Icon(
                  control.closed ? Icons.lock_open : Icons.lock_outline,
                ),
                onPressed:
                    !getIt.isRegistered<AttendanceControlsRepository>() ||
                        (!control.closed && (!ended || busy > 0))
                    ? null
                    : () async {
                        final saved = await showDialog<bool>(
                          context: context,
                          builder: (_) => AttendanceDecisionDialog(
                            repository: getIt<AttendanceControlsRepository>(),
                            workspaceId: membership!.workspace.id,
                            year: month.year,
                            month: month.month,
                            revision: control.revision,
                            closeMonth: !control.closed,
                          ),
                        );
                        if (saved == true && context.mounted) {
                          refreshAttendanceViews(context);
                        }
                      },
                label: Text(
                  context.tr(
                    control.closed
                        ? 'Reopen attendance month'
                        : 'Approve and close month',
                  ),
                ),
              ),
            ],
            if (control.events.isNotEmpty)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(context.tr('Recent attendance decisions')),
                children: [
                  for (final event in control.events)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${event.actor} · ${context.tr(event.action == 'DAY_STATUS'
                            ? 'Change attendance status'
                            : event.action == 'CLOSE_MONTH'
                            ? 'Approve and close month'
                            : 'Reopen attendance month')}',
                      ),
                      subtitle: Text(
                        '${event.employee ?? ''} ${event.operationalDate ?? ''}\n${WorkspaceTime.dateTime(event.date, month.timezone)}\n${event.before == null ? '' : '${context.tr(attendanceDecisionLabel(event.before!))} → '}${event.after == null ? '' : context.tr(attendanceDecisionLabel(event.after!))}\n${event.reason}',
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
