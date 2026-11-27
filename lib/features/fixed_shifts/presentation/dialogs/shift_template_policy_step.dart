import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/clock_time.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/dialogs/shift_template_policy_fields.dart';
import 'package:shiftly/features/fixed_shifts/presentation/utils/shift_templates_formatters.dart';

List<Widget> buildTemplatePolicyStep({
  required BuildContext context,
  required TimeOfDay start,
  required TimeOfDay end,
  required TimeOfDay? breakAt,
  required List<TextEditingController> policies,
  required ShiftTemplateInput input,
  required ManagerTemplatesState state,
  required ValueChanged<TimeOfDay?> onBreakChanged,
  required VoidCallback onPolicyChanged,
}) {
  final locale = Localizations.localeOf(context).toString();
  return [
    ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(context.tr('Break reminder time')),
      subtitle: Text(breakAt?.format(context) ?? context.tr('Not set')),
      trailing: IconButton(
        icon: const Icon(Icons.clear),
        onPressed: state.saving ? null : () => onBreakChanged(null),
      ),
      onTap: state.saving
          ? null
          : () async {
              final time = await showTimePicker(
                context: context,
                initialTime: breakAt ?? const TimeOfDay(hour: 14, minute: 0),
              );
              if (time != null) onBreakChanged(time);
            },
    ),
    buildTemplatePolicyFieldsGrid(
      policies: policies,
      onChanged: onPolicyChanged,
    ),
    const SizedBox(height: 12),
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        context.tr('{value1} – {value2} • {value3} • {value4}', {
          'value1': ClockTime.format(start.hour, start.minute, locale: locale),
          'value2': ClockTime.format(end.hour, end.minute, locale: locale),
          'value3': shiftTemplatesScreenDuration(
            input.durationMinutes,
            context,
          ),
          'value4': context.tr(
            input.durationMinutes == 1440
                ? '24-hour'
                : input.endMinute <= input.startMinute
                ? 'Overnight'
                : 'Same day',
          ),
        }),
      ),
    ),
    if (state.failure != null) ...[
      const SizedBox(height: 10),
      Text(
        shiftTemplatesScreenSupportMessage(
          state.failure!.message,
          state.failure!.requestId,
        ),
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    ],
  ];
}
