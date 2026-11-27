import 'package:flutter/material.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/entities/attendance_calendar_month.dart';
import 'package:shiftly/features/attendance/domain/entities/attendance_month_control.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_controls_repository.dart';
import 'package:shiftly/features/attendance/presentation/refresh_attendance_views.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_decision_dialog.dart';

List<Widget> buildManagerMonthControlActions({
  required BuildContext context,
  required AttendanceCalendarMonth month,
  required AttendanceMonthControl control,
  required String workspaceId,
  required int busy,
  required bool ended,
}) => [
  if (busy > 0)
    Text(
      context.tr(
        'Resolve {count} open records and pending reviews before closing.',
        {'count': '$busy'},
      ),
    ),
  if (!ended && !control.closed)
    Text(
      context.tr('Month approval becomes available after the month ends.'),
    ),
  const SizedBox(height: 8),
  OutlinedButton.icon(
    icon: Icon(control.closed ? Icons.lock_open : Icons.lock_outline),
    onPressed:
        !getIt.isRegistered<AttendanceControlsRepository>() ||
            (!control.closed && (!ended || busy > 0))
        ? null
        : () async {
            final saved = await showDialog<bool>(
              context: context,
              builder: (_) => AttendanceDecisionDialog(
                repository: getIt<AttendanceControlsRepository>(),
                workspaceId: workspaceId,
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
];

Widget buildAttendanceMonthEventsTile(
  BuildContext context,
  AttendanceCalendarMonth month,
  List<AttendanceControlEvent> events,
) => ExpansionTile(
  tilePadding: EdgeInsets.zero,
  title: Text(context.tr('Recent attendance decisions')),
  children: [
    for (final event in events)
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
          '${event.employee ?? ''} ${event.operationalDate ?? ''}\n'
          '${WorkspaceTime.dateTime(event.date, month.timezone)}\n'
          '${event.before == null ? '' : '${context.tr(attendanceDecisionLabel(event.before!))} → '}'
          '${event.after == null ? '' : context.tr(attendanceDecisionLabel(event.after!))}\n'
          '${event.reason}',
        ),
      ),
  ],
);
