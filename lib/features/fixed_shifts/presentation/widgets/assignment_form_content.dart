import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/active_template_selector.dart';
import 'package:shiftly/features/manager_experience/presentation/manager_dialog.dart';

const _weekdayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

Widget buildAssignmentFormContent({
  required BuildContext context,
  required String timezone,
  required bool busy,
  required List<ShiftTemplate>? templates,
  required String? templateId,
  required Set<int> days,
  required DateTime date,
  required String? error,
  required VoidCallback onLoadTemplates,
  required ValueChanged<String?> onTemplateChanged,
  required void Function(int day, bool selected) onDayToggled,
  required VoidCallback onPickDate,
}) => SizedBox(
  width: 480,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        context.tr(
          'Effective dates use {value1}. Saved assignment schedules remain unchanged when a template is edited.',
          {'value1': timezone},
        ),
      ),
      const SizedBox(height: 12),
      if (templates == null)
        TextButton(
          onPressed: busy ? null : onLoadTemplates,
          child: Text(context.tr('Load / retry templates')),
        )
      else if (templates.isEmpty)
        Text(context.tr('No active templates. Create one first.'))
      else
        ActiveTemplateSelector(
          templates: templates,
          value: templateId,
          onChanged: busy ? null : onTemplateChanged,
        ),
      const SizedBox(height: 12),
      Text(context.tr('Expected weekdays')),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (var day = 0; day < 7; day++)
            FilterChip(
              key: Key('weekday-$day'),
              label: Text(context.tr(_weekdayLabels[day])),
              selected: days.contains(day),
              onSelected: busy ? null : (sel) => onDayToggled(day, sel),
            ),
        ],
      ),
      OutlinedButton(
        onPressed: busy ? null : onPickDate,
        child: Text(
          context.tr('Effective {value1}', {
            'value1': WorkspaceTime.localDateKey(
              year: date.year,
              month: date.month,
              day: date.day,
            ),
          }),
        ),
      ),
      if (error != null)
        Text(
          error,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
    ],
  ),
);

Future<bool?> showConfirmAssignmentDialog({
  required BuildContext context,
  required String templateName,
  required String dateKey,
  required String timezone,
}) => showDialog<bool>(
  context: context,
  builder: (c) => ManagerDialog(
    title: Text(context.tr('Replace the baseline assignment?')),
    content: Text(
      context.tr(
        '{value1}\nEffective {value2} · {value3}\nThe previous version ends the day before. Captured history is protected; the server may reject this replacement.',
        {'value1': templateName, 'value2': dateKey, 'value3': timezone},
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(c, false),
        child: Text(context.tr('Back')),
      ),
      FilledButton(
        key: const Key('confirm-work-pattern'),
        onPressed: () => Navigator.pop(c, true),
        child: Text(context.tr('Create version')),
      ),
    ],
  ),
);
