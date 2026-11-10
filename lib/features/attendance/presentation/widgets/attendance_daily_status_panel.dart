import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/entities/calendar_attendance_status.dart';
import 'package:shiftly/features/attendance/presentation/cubit/attendance_calendar_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_cubit.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_calendar_employee_day_row.dart';

/// Derived daily statuses complement clock-in records without creating attendance.
class AttendanceDailyStatusPanel extends StatelessWidget {
  const AttendanceDailyStatusPanel({required this.timezone, super.key});
  final String timezone;

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<ManagerAttendanceCubit, ManagerAttendanceState>(
    builder: (context, attendance) =>
        BlocBuilder<AttendanceCalendarCubit, AttendanceCalendarState>(
          builder: (context, state) {
            final query = attendance.query;
            if (query.from != null ||
                query.to != null ||
                query.reviewStatus != null ||
                query.shiftStatus != null) {
              return const SizedBox.shrink();
            }
            final now = WorkspaceTime.inWorkspace(
              DateTime.now().toUtc(),
              timezone,
            );
            final entries =
                state.data
                    ?.entriesFor(now)
                    .where(
                      (entry) =>
                          (entry.status == CalendarAttendanceStatus.absent ||
                              entry.status == CalendarAttendanceStatus.leave) &&
                          (query.employeeMembershipId == null ||
                              query.employeeMembershipId ==
                                  entry.employeeMembershipId),
                    )
                    .toList() ??
                [];
            if (state.failure != null) {
              return TextButton.icon(
                onPressed: context
                    .read<AttendanceCalendarCubit>()
                    .showCurrentMonth,
                icon: const Icon(Icons.refresh),
                label: Text(context.tr('Could not load attendance')),
              );
            }
            if (entries.isEmpty) return const SizedBox.shrink();
            return Column(
              key: const Key('attendance-today-statuses'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr('Today'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                for (final entry in entries)
                  AttendanceCalendarEmployeeDayRow(
                    entry: entry,
                    timezone: timezone,
                  ),
                const Divider(height: 24),
              ],
            );
          },
        ),
  );
}
