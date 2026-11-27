import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/attendance/presentation/cubit/attendance_calendar_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';

import '../domain/select_employee_schedule_week.dart';
import 'employee_attendance_gate.dart';
import 'employee_schedule_status.dart';
import 'employee_schedule_tiles.dart';
import 'employee_schedule_week_header.dart';

class EmployeeScheduleContent extends StatelessWidget {
  const EmployeeScheduleContent({
    required this.calendar,
    required this.state,
    required this.timezone,
    required this.week,
    required this.onMove,
    required this.onRetry,
    super.key,
  });

  final AttendanceCalendarState calendar;
  final FlexibleAttendanceState state;
  final String timezone;
  final int week;
  final Future<void> Function(int) onMove;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final data = calendar.data;
    final allEntries = state.eligibility?.authorizedOccurrences ?? const [];
    final locale = Localizations.localeOf(context).toString();
    final month = DateTime(
      calendar.year ?? DateTime.now().year,
      calendar.month ?? DateTime.now().month,
    );
    final (firstDay, lastDay) = scheduleWeekBounds(month, week);
    final (entries, visibleShifts) = selectEmployeeScheduleWeek(
      month: month,
      firstDay: firstDay,
      lastDay: lastDay,
      timezone: timezone,
      entries: allEntries,
      shifts: data?.scheduledShifts ?? const [],
    );
    return ListView(
      key: const Key('employee-schedule'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        EmployeeScheduleWeekHeader(
          firstDay: firstDay,
          lastDay: lastDay,
          month: month,
          timezone: timezone,
          busy: calendar.loading || calendar.refreshing,
          onMove: onMove,
        ),
        const SizedBox(height: 20),
        if (state.recovery != null ||
            state.recoveryBlocked ||
            state.legacyReviewRequired ||
            (entries.isEmpty && allEntries.isEmpty)) ...[
          EmployeeAttendanceGate(state: state, timezone: timezone),
          const SizedBox(height: 16),
        ],
        ...employeeScheduleStatus(context, calendar, onRetry: onRetry),
        ...buildScheduleOccurrenceTiles(
          context: context,
          entries: entries,
          month: month,
          locale: locale,
          timezone: timezone,
        ),
        ...buildScheduledShiftTiles(
          context: context,
          visibleShifts: visibleShifts,
          entries: entries,
          locale: locale,
          timezone: timezone,
        ),
        if (!calendar.loading &&
            data != null &&
            visibleShifts.isEmpty &&
            entries.isEmpty)
          Text(context.tr('No scheduled shifts in this week.')),
      ],
    );
  }
}
