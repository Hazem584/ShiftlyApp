part of '../../attendance_calendar_selected_day.dart';

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
        'Shift ${WorkspaceTime.time(entry.shift!.startsAt, timezone, locale: Localizations.localeOf(context).toString())}–${WorkspaceTime.time(entry.shift!.endsAt, timezone, locale: Localizations.localeOf(context).toString())}',
      if (entry.attendance != null)
        'In ${WorkspaceTime.time(entry.attendance!.clockInAt, timezone, locale: Localizations.localeOf(context).toString())}',
      if (entry.attendance?.clockOutAt != null)
        'Out ${WorkspaceTime.time(entry.attendance!.clockOutAt, timezone, locale: Localizations.localeOf(context).toString())}',
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
