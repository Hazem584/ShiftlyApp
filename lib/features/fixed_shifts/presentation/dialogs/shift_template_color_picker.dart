import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/clock_time.dart';
import 'package:shiftly/features/fixed_shifts/presentation/utils/shift_templates_formatters.dart';

const templatePresetColors = [
  '#2563EB',
  '#0F766E',
  '#7C3AED',
  '#C2410C',
  '#BE123C',
  '#334155',
];

Widget buildTemplateTimeButtons({
  required BuildContext context,
  required TimeOfDay start,
  required TimeOfDay end,
  required bool saving,
  required void Function(bool) onPickTime,
}) {
  final locale = Localizations.localeOf(context).toString();
  return Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      OutlinedButton.icon(
        onPressed: saving ? null : () => onPickTime(true),
        icon: const Icon(Icons.login_rounded),
        label: Text(
          context.tr('Start {value1}', {
            'value1': ClockTime.format(start.hour, start.minute, locale: locale),
          }),
        ),
      ),
      OutlinedButton.icon(
        onPressed: saving ? null : () => onPickTime(false),
        icon: const Icon(Icons.logout_rounded),
        label: Text(
          context.tr('End {value1}', {
            'value1': ClockTime.format(end.hour, end.minute, locale: locale),
          }),
        ),
      ),
    ],
  );
}

Widget buildTemplateColorPicker({
  required BuildContext context,
  required String colorValue,
  required bool saving,
  required ValueChanged<String> onColorChanged,
}) => Semantics(
  label: context.tr('Template color'),
  child: Wrap(
    spacing: 10,
    children: [
      if (!templatePresetColors.contains(colorValue))
        ChoiceChip(
          label: Text(colorValue),
          avatar: CircleAvatar(
            backgroundColor: shiftTemplatesScreenColor(colorValue),
          ),
          selected: true,
          onSelected: null,
        ),
      for (final value in templatePresetColors)
        ChoiceChip(
          label: const SizedBox.square(dimension: 20),
          avatar: CircleAvatar(
            backgroundColor: shiftTemplatesScreenColor(value),
          ),
          selected: colorValue == value,
          onSelected: saving ? null : (_) => onColorChanged(value),
        ),
    ],
  ),
);
