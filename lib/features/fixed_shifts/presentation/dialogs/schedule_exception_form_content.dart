import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/active_template_selector.dart';

Widget buildScheduleExceptionFormContent({
  required BuildContext context,
  required GlobalKey<FormState> formKey,
  required String? employeeMembershipId,
  required String kind,
  required String dateKey,
  required String timezone,
  required List<ShiftTemplate> templates,
  required String? templateId,
  required TextEditingController reason,
  required String? error,
  required bool busy,
  required ValueChanged<String> onKindChanged,
  required VoidCallback onPickDate,
  required ValueChanged<String?> onTemplateChanged,
}) => SizedBox(
  width: 480,
  child: SingleChildScrollView(
    child: Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr(
              'Changes apply to this date only. Recorded attendance cannot be changed.',
            ),
          ),
          const SizedBox(height: 12),
          if (employeeMembershipId != null)
            DropdownButtonFormField<String>(
              initialValue: kind,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: context.tr('Exception type'),
              ),
              items: [
                DropdownMenuItem(
                  value: 'SHIFT',
                  child: Text(context.tr('One-day shift change')),
                ),
                DropdownMenuItem(
                  value: 'DAY_OFF',
                  child: Text(context.tr('Employee day off')),
                ),
              ],
              onChanged: busy ? null : (v) => onKindChanged(v!),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: busy ? null : onPickDate,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text('$dateKey · $timezone'),
          ),
          if (kind == 'SHIFT') ...[
            const SizedBox(height: 12),
            ActiveTemplateSelector(
              templates: templates,
              value: templateId,
              onChanged: busy ? null : onTemplateChanged,
            ),
            if (templates.isEmpty)
              Text(context.tr('Create an active fixed-shift template first.')),
          ],
          const SizedBox(height: 12),
          TextFormField(
            controller: reason,
            enabled: !busy,
            minLines: 2,
            maxLines: 4,
            maxLength: 1000,
            decoration: InputDecoration(labelText: context.tr('Reason')),
            validator: (v) => (v?.trim().length ?? 0) < 5
                ? context.tr('Enter a reason of at least 5 characters.')
                : null,
          ),
          if (error != null)
            Text(
              context.tr(error),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
  ),
);
