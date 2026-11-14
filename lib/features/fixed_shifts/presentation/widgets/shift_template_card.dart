import 'package:flutter/material.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/utils/shift_templates_formatters.dart';
import 'package:shiftly/features/manager_experience/presentation/manager_template_details.dart';

class ShiftTemplateCard extends StatelessWidget {
  const ShiftTemplateCard({
    super.key,
    required this.template,
    required this.busy,
    required this.onEdit,
    required this.onArchive,
  });
  final ShiftTemplate template;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Icon(Icons.schedule_outlined, color: color.onSurfaceVariant),
        title: Text(template.name),
        subtitle: Text(
          '${shiftTemplatesScreenTod(template.startMinute).format(context)} – ${shiftTemplatesScreenTod(template.endMinute).format(context)}${template.overnight ? ' +1' : ''}',
        ),
        trailing: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
        onTap: busy
            ? null
            : () => showDialog<void>(
                context: context,
                builder: (_) => ManagerTemplateDetails(
                  template: template,
                  onEdit: onEdit,
                  onArchive: onArchive,
                ),
              ),
      ),
    );
  }
}
