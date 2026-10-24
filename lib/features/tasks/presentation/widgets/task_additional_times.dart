import 'package:day_night_time_picker/day_night_time_picker.dart' as picker;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shiftly/core/localization/app_localizations.dart';

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
          (entry) => entry.$1 != index && entry.$2.isAtSameMomentAs(date),
        )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Choose a different future alarm time.')),
        ),
      );
      return;
    }
    final next = [...dates];
    if (index == null) {
      next.add(date);
    } else {
      next[index] = date;
    }
    next.sort((a, b) => a.compareTo(b));
    onChanged(next);
  }

  DateTime _nextWeek() {
    final last = [primary, ...dates]..sort((a, b) => a.compareTo(b));
    final value = last.last.toLocal();
    return DateTime(
      value.year,
      value.month,
      value.day + 7,
      value.hour,
      value.minute,
    );
  }

  Future<void> _pick(BuildContext context, {int? index}) async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final initial = index == null ? _nextWeek() : dates[index].toLocal();
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 100, 12, 31),
    );
    if (date == null || !context.mounted) return;
    picker.Time? chosen;
    await Navigator.of(context).push(
      picker.showPicker(
        context: context,
        value: picker.Time(hour: initial.hour, minute: initial.minute),
        onChange: (time) => chosen = time,
        themeData: Theme.of(context),
        accentColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).colorScheme.surface,
        width: (MediaQuery.sizeOf(context).width - 48).clamp(240.0, 380.0),
        ltrMode: Directionality.of(context) == TextDirection.ltr,
        is24HrFormat: MediaQuery.alwaysUse24HourFormatOf(context),
        amLabel: MaterialLocalizations.of(context).anteMeridiemAbbreviation,
        pmLabel: MaterialLocalizations.of(context).postMeridiemAbbreviation,
        cancelText: context.tr('Cancel'),
        okText: context.tr('Confirm time'),
        borderRadius: 24,
        dialogInsetPadding: const EdgeInsets.all(16),
      ),
    );
    final time = chosen;
    if (time == null || !context.mounted) return;
    _set(
      context,
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
      index: index,
    );
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
        for (final (index, date) in dates.indexed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_repeat_rounded),
            title: Text(
              DateFormat.yMMMd(locale).add_jm().format(date.toLocal()),
            ),
            onTap: enabled ? () => _pick(context, index: index) : null,
            trailing: IconButton(
              key: Key('remove-alarm-$index'),
              tooltip: context.tr('Remove alarm time'),
              icon: const Icon(Icons.close_rounded),
              onPressed: enabled
                  ? () => onChanged([...dates]..removeAt(index))
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
