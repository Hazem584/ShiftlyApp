import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/manager_form_page.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/utils/shift_templates_formatters.dart';

class ManagerTemplateDetails extends StatelessWidget {
  const ManagerTemplateDetails({
    required this.template,
    required this.onEdit,
    required this.onArchive,
    super.key,
  });
  final ShiftTemplate template;
  final VoidCallback onEdit, onArchive;
  @override
  Widget build(BuildContext context) => ManagerFormPage(
    title: template.name,
    subtitle: template.description,
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.schedule_outlined),
            title: Text(
              '${shiftTemplatesScreenTod(template.startMinute).format(context)} – ${shiftTemplatesScreenTod(template.endMinute).format(context)}',
            ),
            subtitle: Text(
              context.tr(
                template.overnight
                    ? 'Ends the following day'
                    : 'Same-day shift',
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final value in [
          ('Grace minutes', template.graceMinutes),
          ('Early check-in minutes', template.allowedEarlyCheckInMinutes),
          ('Late check-in minutes', template.allowedLateCheckInMinutes),
          ('Minimum work minutes', template.minimumWorkMinutes),
          ('Break minutes', template.breakMinutes),
        ]) ...[
          Card(
            child: ListTile(
              title: Text(context.tr(value.$1)),
              trailing: Text('${value.$2}'),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    ),
    actions: [
      if (template.active) ...[
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onArchive();
          },
          child: Text(context.tr('Archive template')),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            onEdit();
          },
          child: Text(context.tr('Edit template')),
        ),
      ] else
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('Done')),
        ),
    ],
  );
}
