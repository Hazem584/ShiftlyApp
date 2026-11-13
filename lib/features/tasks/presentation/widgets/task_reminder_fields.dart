import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_tile.dart';

import 'task_additional_times.dart';

class TaskReminderFields extends StatelessWidget {
  const TaskReminderFields({
    required this.dueAt,
    required this.duration,
    required this.day,
    required this.hour,
    required this.dates,
    required this.busy,
    required this.onDay,
    required this.onHour,
    required this.onDates,
    super.key,
  });
  final DateTime dueAt;
  final int? duration;
  final bool day, hour, busy;
  final List<DateTime> dates;
  final ValueChanged<bool> onDay, onHour;
  final ValueChanged<List<DateTime>> onDates;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final finish = duration == null
        ? ''
        : ' → ${DateFormat.Hm(locale).format(dueAt.add(Duration(minutes: duration!)))}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EmployeeTile(
          icon: Icons.alarm_outlined,
          title: context.tr('At start and end'),
          subtitle: '${DateFormat.Hm(locale).format(dueAt)}$finish',
        ),
        const SizedBox(height: 24),
        Text(
          context.tr('Additional reminders'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        CheckboxListTile(
          key: const Key('task-remind-hour'),
          contentPadding: EdgeInsets.zero,
          title: Text(context.tr('Remind me one hour before')),
          value: hour,
          onChanged: busy ? null : (v) => onHour(v ?? false),
        ),
        CheckboxListTile(
          key: const Key('task-remind-day'),
          contentPadding: EdgeInsets.zero,
          title: Text(context.tr('Remind me one day before')),
          value: day,
          onChanged: busy ? null : (v) => onDay(v ?? false),
        ),
        const SizedBox(height: 16),
        TaskAdditionalTimes(
          primary: dueAt,
          dates: dates,
          enabled: !busy,
          onChanged: onDates,
        ),
      ],
    );
  }
}
