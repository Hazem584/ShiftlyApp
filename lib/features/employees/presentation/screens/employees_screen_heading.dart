import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class EmployeesScreenHeading extends StatelessWidget {
  const EmployeesScreenHeading({required this.total, super.key});
  final int? total;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('Your team'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          total != null
              ? context.tr('{count} people', {'count': '$total'})
              : context.tr('Manage your workspace team'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  );
}
