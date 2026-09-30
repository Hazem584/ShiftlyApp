import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/data/attendance_calendar_repository.dart';
import 'package:shiftly/features/attendance/data/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_calendar_legend.dart';

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
      return const _SelectedDayEmpty(
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
                (entry) => _EmployeeDayRow(entry: entry, timezone: timezone),
              ),
          ],
        ),
      ),
    );
  }
}

class _SelectedDayEmpty extends StatelessWidget {
  const _SelectedDayEmpty({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}

class _EmployeeDayRow extends StatelessWidget {
  const _EmployeeDayRow({required this.entry, required this.timezone});
  final AttendanceCalendarEntry entry;
  final String timezone;

  @override
  Widget build(BuildContext context) {
    final name = entry.employee.displayName;
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
    final details = <String>[
      if (entry.shift != null)
        'Shift ${WorkspaceTime.time(entry.shift!.startsAt, timezone)}–${WorkspaceTime.time(entry.shift!.endsAt, timezone)}',
      if (entry.attendance != null)
        'In ${WorkspaceTime.time(entry.attendance!.clockInAt, timezone)}',
      if (entry.attendance?.clockOutAt != null)
        'Out ${WorkspaceTime.time(entry.attendance!.clockOutAt, timezone)}',
      if ((entry.attendance?.minutesLate ?? 0) > 0)
        '${entry.attendance!.minutesLate} min late',
      if (entry.leave != null) _leaveLabel(entry.leave!.type),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            foregroundImage: entry.employee.avatarUrl == null
                ? null
                : NetworkImage(entry.employee.avatarUrl!),
            child: Text(initials.isEmpty ? '?' : initials),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
                if (details.isNotEmpty)
                  Text(
                    details.join(' • '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              calendarStatusLabel(entry.status),
              style: TextStyle(
                color: calendarStatusColor(entry.status),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _leaveLabel(LeaveRequestType type) => switch (type) {
    LeaveRequestType.annualLeave => 'Annual leave',
    LeaveRequestType.sickLeave => 'Sick leave',
    LeaveRequestType.emergencyLeave => 'Emergency leave',
    LeaveRequestType.earlyLeave => 'Early leave',
    LeaveRequestType.other => 'Other leave',
    LeaveRequestType.unknown => 'Leave',
  };
}
