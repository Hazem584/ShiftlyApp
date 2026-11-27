import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shiftly/core/localization/app_localizations.dart';

import 'task_date_time_picker.dart';

class TaskAdditionalTimes extends StatelessWidget {
  const TaskAdditionalTimes({
    required this.primary,
    required this.dates,
    required this.onChanged,
    required this.enabled,
    super.key,
  });
  final DateTime primary;
  final List<DateTime> dates;
  final ValueChanged<List<DateTime>> onChanged;
  final bool enabled;

  void _set(BuildContext context, DateTime date, {int? index}) {
    if (!date.isAfter(DateTime.now()) ||
        date.isAtSameMomentAs(primary) ||
        dates.indexed.any(
          (e) => e.$1 != index && e.$2.isAtSameMomentAs(date),
        )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Choose a different future alarm time.')),
        ),
      );
      return;
    }
    final next = [...dates];
    index == null ? next.add(date) : next[index] = date;
    next.sort((a, b) => a.compareTo(b));
    onChanged(next);
  }

  DateTime _nextWeek() {
    final last = [primary, ...dates]..sort((a, b) => a.compareTo(b));
    final v = last.last.toLocal();
    return DateTime(v.year, v.month, v.day + 7, v.hour, v.minute);
  }

  Future<void> _pick(BuildContext context, {int? index}) async {
    FocusScope.of(context).unfocus();
    final initial = index == null ? _nextWeek() : dates[index].toLocal();
    final date = await pickTaskCalendarDate(context, initial);
    if (date == null || !context.mounted) return;
    final picked = await pickTaskClockTime(context, date, initialTime: initial);
    if (picked != null && context.mounted) _set(context, picked, index: index);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr('More alarm times'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          context.tr('One task, the same title and details at every time.'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        for (final (i, date) in dates.indexed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_repeat_rounded),
            title: Text(
              DateFormat.yMMMd(locale).add_jm().format(date.toLocal()),
            ),
            onTap: enabled ? () => _pick(context, index: i) : null,
            trailing: IconButton(
              key: Key('remove-alarm-$i'),
              tooltip: context.tr('Remove alarm time'),
              icon: const Icon(Icons.close_rounded),
              onPressed: enabled
                  ? () => onChanged([...dates]..removeAt(i))
                  : null,
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              key: const Key('add-task-alarm'),
              onPressed: enabled && dates.length < 49
                  ? () => _pick(context)
                  : null,
              icon: const Icon(Icons.add_alarm_rounded),
              label: Text(context.tr('Add alarm time')),
            ),
            TextButton.icon(
              key: const Key('add-task-week'),
              onPressed: enabled && dates.length < 49
                  ? () => _set(context, _nextWeek())
                  : null,
              icon: const Icon(Icons.date_range_rounded),
              label: Text(context.tr('Add next week')),
            ),
          ],
        ),
      ],
    );
  }
}
