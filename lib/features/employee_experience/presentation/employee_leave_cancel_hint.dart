import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class EmployeeLeaveCancelHint extends StatelessWidget {
  const EmployeeLeaveCancelHint({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      context.tr('You can cancel while this request is pending.'),
      style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
    ),
  );
}
