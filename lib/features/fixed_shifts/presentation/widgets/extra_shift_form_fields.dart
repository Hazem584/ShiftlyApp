import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/extra_authorization_card.dart';
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
      buildExtraTemplateField(
        context: context,
        templates: templates,
        templateId: templateId,
        busy: busy,
        onLoadTemplates: onLoadTemplates,
        onTemplateChanged: onTemplateChanged,
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: busy ? null : onPickDate,
        icon: const Icon(Icons.calendar_today_outlined, size: 18),
        label: Text(
          '${context.tr('Date')}: ${WorkspaceTime.localDateKey(year: date.year, month: date.month, day: date.day)}',
        ),
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        initialValue: reason,
        isExpanded: true,
        decoration: InputDecoration(labelText: context.tr('Reason')),
        items: [
          for (final v in extraShiftReasons)
            DropdownMenuItem(
              value: v,
              child: Text(
                extraShiftReasonLabel(context, v),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: busy ? null : (v) => onReasonChanged(v!),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: explanation,
        enabled: !busy,
        maxLength: 1000,
        minLines: 2,
        maxLines: 4,
        decoration: InputDecoration(labelText: context.tr('Notes')),
      ),
      if (actual)
        ...buildExtraShiftActualFields(
          context: context,
          actualIn: actualIn,
          actualOut: actualOut,
          busy: busy,
        ),
      if (error != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            context.tr(error),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
    ],
  ),
);
