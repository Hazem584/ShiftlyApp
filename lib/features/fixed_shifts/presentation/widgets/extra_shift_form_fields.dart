import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/extra_shift_form_actual_fields.dart';

Widget buildExtraShiftFormContent({
  required BuildContext context,
  required String timezone,
  required bool actual,
  required bool busy,
  required bool hasIntent,
  required List<ShiftTemplate>? templates,
  required String? templateId,
  required DateTime date,
  required String reason,
  required String? error,
  required TextEditingController explanation,
  required TextEditingController actualIn,
  required TextEditingController actualOut,
  required VoidCallback onLoadTemplates,
  required ValueChanged<String?> onTemplateChanged,
  required VoidCallback onPickDate,
  required ValueChanged<String> onReasonChanged,
  required VoidCallback onRecover,
}) => SizedBox(
  width: 480,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        context.tr(
          'Times and operational dates in {value1}. Overnight shifts use their start date.',
          {'value1': timezone},
        ),
      ),
      const SizedBox(height: 12),
      buildExtraTemplateField(
        context: context,
        templates: templates,
        templateId: templateId,
        busy: busy,
        onLoadTemplates: onLoadTemplates,
        onTemplateChanged: onTemplateChanged,
      ),
      OutlinedButton(
        onPressed: busy ? null : onPickDate,
        child: Text(
          context.tr('Operational date {value1}', {
            'value1': WorkspaceTime.localDateKey(
              year: date.year,
              month: date.month,
              day: date.day,
            ),
          }),
        ),
      ),
      DropdownButtonFormField<String>(
        initialValue: reason,
        isExpanded: true,
        decoration: InputDecoration(labelText: context.tr('Structured reason')),
        items: [
          for (final v in extraShiftReasons)
            DropdownMenuItem(
              value: v,
              child: Text(
                Localizations.localeOf(context).languageCode == 'ar'
                    ? context.tr(v)
                    : v.replaceAll('_', ' '),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: busy ? null : (v) => onReasonChanged(v!),
      ),
      TextField(
        controller: explanation,
        enabled: !busy,
        maxLength: 1000,
        minLines: 2,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: context.tr('Explanation (3–1000 characters)'),
        ),
      ),
      if (actual)
        ...buildExtraShiftActualFields(
          context: context,
          actualIn: actualIn,
          actualOut: actualOut,
          busy: busy,
        ),
      if (hasIntent)
        FilledButton.tonal(
          onPressed: busy ? null : onRecover,
          child: Text(context.tr('Recover saved extra operation')),
        ),
      if (error != null)
        Text(
          error,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
    ],
  ),
);
