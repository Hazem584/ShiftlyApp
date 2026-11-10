import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_calendar_repository.dart';
import 'package:shiftly/features/attendance/presentation/refresh_attendance_views.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/edit_attendance_day_dialog.dart';

class AttendanceDayEntryActions extends StatelessWidget {
  const AttendanceDayEntryActions({
    required this.entry,
    required this.date,
    required this.timezone,
    super.key,
  });
  final AttendanceCalendarEntry entry;
  final DateTime date;
  final String timezone;
  @override
  Widget build(BuildContext context) {
    final membership = context
        .watch<SessionCoordinator?>()
        ?.state
        .activeMembership;
    final end = entry.attendance?.clockOutAt ?? entry.shift?.endsAt;
    if (membership == null ||
        end == null ||
        end.isAfter(DateTime.now()) ||
        entry.attendance?.isOpen == true) {
      return const SizedBox.shrink();
    }
    final manager = membership.role == WorkspaceRole.manager;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: OutlinedButton.icon(
        key: Key('correct-attendance-${entry.employeeMembershipId}'),
        icon: const Icon(Icons.edit_calendar_outlined),
        label: Text(
          context.tr(
            manager ? 'Edit attendance' : 'Request attendance correction',
          ),
        ),
        onPressed: () async {
          final saved = await showDialog<bool>(
            context: context,
            builder: (_) => EditAttendanceDayDialog(
              entry: entry,
              date: date,
              workspaceId: membership.workspace.id,
              timezone: timezone,
              manager: manager,
              repository: getIt<TeamWorkRepository>(),
            ),
          );
          if (saved == true && context.mounted) refreshAttendanceViews(context);
        },
      ),
    );
  }
}
