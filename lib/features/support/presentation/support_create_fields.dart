import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import '../domain/support_models.dart';

class SupportCreateFields extends StatelessWidget {
  const SupportCreateFields({
    required this.titleController,
    required this.descriptionController,
    required this.contexts,
    required this.editable,
    required this.onRelatedChanged,
    super.key,
  });
  final TextEditingController titleController, descriptionController;
  final List<SupportContext> contexts;
  final bool editable;
  final ValueChanged<SupportContext?> onRelatedChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextFormField(
        controller: titleController,
        enabled: editable,
        maxLength: 120,
        decoration: InputDecoration(labelText: context.tr('Problem title')),
        validator: (v) => (v?.trim().length ?? 0) < 3
            ? context.tr('Enter a title of at least 3 characters.')
            : null,
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<SupportContext?>(
        initialValue: null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: context.tr('Related task or shift (optional)'),
        ),
        items: [
          DropdownMenuItem(
            value: null,
            child: Text(context.tr('General problem')),
          ),
          for (final v in contexts)
            DropdownMenuItem(
              value: v,
              child: Text(
                v.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: editable ? onRelatedChanged : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: descriptionController,
        enabled: editable,
        minLines: 5,
        maxLines: 10,
        maxLength: 5000,
        decoration: InputDecoration(
          labelText: context.tr('Describe what happened'),
        ),
        validator: (v) => (v?.trim().length ?? 0) < 10
            ? context.tr('Describe the problem in at least 10 characters.')
            : null,
      ),
    ],
  );
}
