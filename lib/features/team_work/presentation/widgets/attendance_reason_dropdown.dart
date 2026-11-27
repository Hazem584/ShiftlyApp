import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class AttendanceReasonDropdown extends StatelessWidget {
  const AttendanceReasonDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.busy,
    required this.onChanged,
  });
  final String value, label;
  final bool busy;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: context.tr(label)),
      items: [
        for (final (code, text) in const [
          ('FORGOT_TO_RECORD', 'I attended but forgot to record attendance'),
          ('EXCEPTION', 'I have an exception or special circumstance'),
          ('OTHER', 'Other reason'),
        ])
          DropdownMenuItem(
            value: code,
            child: Text(context.tr(text), maxLines: 2),
          ),
      ],
      onChanged: busy ? null : (v) => onChanged(v!),
    );
  }
}
