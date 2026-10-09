import 'package:flutter/material.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';

class ActiveTemplateSelector extends StatelessWidget {
  const ActiveTemplateSelector({
    required this.templates,
    required this.value,
    required this.onChanged,
    super.key,
  });
  final List<ShiftTemplate> templates;
  final String? value;
  final ValueChanged<String?>? onChanged;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    decoration: const InputDecoration(labelText: 'Active fixed-shift template'),
    items: [
      for (final template in templates.where((v) => v.active))
        DropdownMenuItem(
          value: template.id,
          child: Text(template.name, overflow: TextOverflow.ellipsis),
        ),
    ],
    onChanged: onChanged,
  );
}
