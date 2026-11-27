import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/team_work/presentation/utils/attendance_review_instants.dart';

Future<void> pickAttendanceReviewInstant(
  BuildContext context,
  DateTime value,
  String timezone,
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
                  child: Text(_formatInstantOption(context, instant, timezone)),
                ),
            ],
          ),
        );
  if (chosen != null && context.mounted) change(chosen);
}

String _formatInstantOption(
  BuildContext context,
  DateTime instant,
  String timezone,
) {
  final local = WorkspaceTime.inWorkspace(instant, timezone);
  final offset = local.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final h = offset.inHours.abs().toString().padLeft(2, '0');
  final m = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
  final formatted = WorkspaceTime.dateTime(
    instant,
    timezone,
    locale: Localizations.localeOf(context).toString(),
  );
  return '$formatted (UTC$sign$h:$m)';
}
