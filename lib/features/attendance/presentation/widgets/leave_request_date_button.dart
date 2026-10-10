import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class LeaveRequestDateButton extends StatelessWidget {
  const LeaveRequestDateButton({
    super.key,
    required this.label,
    required this.value,
    required this.onPressed,
  });
  final String label;
  final DateTime value;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.calendar_today_outlined),
    label: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        context.tr('{value1}: {value2}-{value3}-{value4}', {
          'value1': (label).toString(),
          'value2': (value.year).toString(),
          'value3': (value.month.toString().padLeft(2, '0')).toString(),
          'value4': (value.day.toString().padLeft(2, '0')).toString(),
        }),
      ),
    ),
  );
}
