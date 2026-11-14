import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class ManagerActionLinks extends StatelessWidget {
  const ManagerActionLinks({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in const [
          ('Team records', 'attendance'),
          ('Team requests', 'leave'),
          ('Review requests', 'corrections'),
          ('Monthly calendar', 'calendar'),
        ])
          ActionChip(
            label: Text(context.tr(item.$1)),
            onPressed: () => context.go('/work?tab=${item.$2}'),
          ),
      ],
    ),
  );
}
