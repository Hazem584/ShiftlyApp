import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/team_work/presentation/utils/attendance_period_picker.dart';

class AttendancePeriodFields extends StatelessWidget {
  const AttendancePeriodFields({
    super.key,
    required this.start,
    required this.end,
    required this.timezone,
    required this.onStart,
    required this.onEnd,
    this.busy = false,
  });
  final DateTime start, end;
  final String timezone;
  final ValueChanged<DateTime> onStart, onEnd;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    String time(DateTime value) => WorkspaceTime.dateTime(
      value,
      timezone,
      locale: Localizations.localeOf(context).toString(),
    );
    final minutes = end.difference(start).inMinutes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.tr('Clock in')),
          subtitle: Text(time(start)),
          trailing: const Icon(Icons.edit_calendar_outlined),
          onTap: busy
              ? null
              : () => pickAttendanceReviewInstant(
                  context,
                  start,
                  timezone,
                  onStart,
                ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.tr('Clock out')),
          subtitle: Text(time(end)),
          trailing: const Icon(Icons.edit_calendar_outlined),
          onTap: busy
              ? null
              : () =>
                    pickAttendanceReviewInstant(context, end, timezone, onEnd),
        ),
        Text(
          context.tr('Period to count: {hours}h {minutes}m', {
            'hours': '${minutes ~/ 60}',
            'minutes': '${minutes % 60}',
          }),
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
  }
}
