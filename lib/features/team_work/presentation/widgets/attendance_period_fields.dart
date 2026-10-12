import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/team_work/presentation/utils/attendance_review_instants.dart';

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

  Future<void> _pick(
    BuildContext context,
    DateTime value,
    ValueChanged<DateTime> change,
  ) async {
    final local = WorkspaceTime.inWorkspace(value, timezone);
    final today = WorkspaceTime.inWorkspace(DateTime.now(), timezone);
    final date = await showDatePicker(
      context: context,
      initialDate: local,
      firstDate: DateTime(local.year - 1),
      lastDate: DateTime(today.year, today.month, today.day),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(local),
    );
    if (time == null || !context.mounted) return;
    final instants = attendanceReviewInstants(
      date,
      time.hour,
      time.minute,
      timezone,
    );
    if (instants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('This local time is unavailable. Choose another time.'),
          ),
        ),
      );
      return;
    }
    final chosen = instants.length == 1
        ? instants.single
        : await showDialog<DateTime>(
            context: context,
            builder: (context) => SimpleDialog(
              title: Text(
                context.tr('This time occurs twice. Choose the intended time.'),
              ),
              children: [
                for (final instant in instants)
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, instant),
                    child: Text(
                      '${WorkspaceTime.dateTime(instant, timezone, locale: Localizations.localeOf(context).toString())} (UTC${WorkspaceTime.inWorkspace(instant, timezone).timeZoneOffset.isNegative ? '-' : '+'}${WorkspaceTime.inWorkspace(instant, timezone).timeZoneOffset.inHours.abs().toString().padLeft(2, '0')}:${(WorkspaceTime.inWorkspace(instant, timezone).timeZoneOffset.inMinutes.abs() % 60).toString().padLeft(2, '0')})',
                    ),
                  ),
              ],
            ),
          );
    if (chosen != null && context.mounted) change(chosen);
  }

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
          onTap: busy ? null : () => _pick(context, start, onStart),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.tr('Clock out')),
          subtitle: Text(time(end)),
          trailing: const Icon(Icons.edit_calendar_outlined),
          onTap: busy ? null : () => _pick(context, end, onEnd),
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
