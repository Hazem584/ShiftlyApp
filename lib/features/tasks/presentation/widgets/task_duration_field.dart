import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class TaskDurationField extends StatelessWidget {
  const TaskDurationField({
    required this.controller,
    required this.busy,
    super.key,
  });
  final TextEditingController controller;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const Key('task-duration'),
      controller: controller,
      enabled: !busy,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: context.tr('Duration · Optional')),
      validator: (v) {
        if (v == null || v.isEmpty) return null;
        final n = int.tryParse(v);
        return n == null || n < 1 || n > 10080
            ? context.tr('Choose a duration from 1 to 10080 minutes.')
            : null;
      },
    );
  }
}
