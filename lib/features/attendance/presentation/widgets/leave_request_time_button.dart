import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/clock_time.dart';

class LeaveRequestTimeButton extends StatelessWidget {
  const LeaveRequestTimeButton({
    super.key,
    required this.label,
    required this.value,
    required this.onPressed,
  });
  final String label;
  final TimeOfDay value;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    child: Text(
      context.tr('{value1}: {value2}', {
        'value1': (label).toString(),
        'value2': (ClockTime.format(
          value.hour,
          value.minute,
          locale: Localizations.localeOf(context).toString(),
        )).toString(),
      }),
    ),
  );
}
