import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_calendar_repository.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_calendar_employee_day_row.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_calendar_selected_day_empty.dart';

class AttendanceCalendarSelectedDay extends StatelessWidget {
  const AttendanceCalendarSelectedDay({
    required this.date,
    required this.timezone,
    required this.entries,
    super.key,
  });

  final DateTime? date;
  final String timezone;
  final List<AttendanceCalendarEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (date == null) {
      return const AttendanceCalendarSelectedDayEmpty(
        message: 'Select a date to see employee details.',
      );
    }
    final key = WorkspaceTime.localDateKey(
      year: date!.year,
      month: date!.month,
      day: date!.day,
    );
    return Card(
      key: const Key('calendar-selected-day'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(key, style: Theme.of(context).textTheme.titleMedium),
            Text(timezone, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.s),
            if (entries.isEmpty)
              const Text('No attendance events for this date.')
            else
              ...entries.map(
                (entry) => AttendanceCalendarEmployeeDayRow(
                  entry: entry,
                  timezone: timezone,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
