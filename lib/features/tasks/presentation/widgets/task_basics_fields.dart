import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class TaskBasicsFields extends StatelessWidget {
  const TaskBasicsFields({
    required this.title,
    required this.description,
    required this.duration,
    required this.dueAt,
    required this.busy,
    required this.pickDate,
    required this.pickTime,
    super.key,
  });
  final TextEditingController title, description, duration;
  final DateTime dueAt;
  final bool busy;
  final VoidCallback pickDate, pickTime;
  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: title,
          enabled: !busy,
          maxLength: 160,
          decoration: InputDecoration(labelText: context.tr('Task title')),
          validator: (v) => (v ?? '').trim().isEmpty
              ? context.tr('Enter a task title.')
              : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const Key('task-description'),
          controller: description,
          enabled: !busy,
          minLines: 3,
          maxLines: 6,
          maxLength: 5000,
          decoration: InputDecoration(
            labelText: context.tr('Description'),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),
        Text(context.tr('Scheduled date / time')),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: busy ? null : pickDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(DateFormat.yMMMd(locale).format(dueAt)),
            ),
            OutlinedButton.icon(
              key: const Key('task-time-picker'),
              onPressed: busy ? null : pickTime,
              icon: const Icon(Icons.schedule),
              label: Text(DateFormat.Hm(locale).format(dueAt)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextFormField(
          key: const Key('task-duration'),
          controller: duration,
          enabled: !busy,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: context.tr('Duration · Optional'),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return null;
            final n = int.tryParse(v);
            return n == null || n < 1 || n > 10080
                ? context.tr('Choose a duration from 1 to 10080 minutes.')
                : null;
          },
        ),
        const SizedBox(height: 12),
        Text(
          context.tr('Time is shown in your device timezone.'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
