import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class WeekdayRow extends StatelessWidget {
  const WeekdayRow({required this.days, super.key});
  final List<int> days;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 5,
    runSpacing: 5,
    children: [
      for (final day in days)
        Chip(
          label: Text(
            [
              context.tr('Sun'),
              context.tr('Mon'),
              context.tr('Tue'),
              context.tr('Wed'),
              context.tr('Thu'),
              context.tr('Fri'),
              context.tr('Sat'),
            ][day],
          ),
          visualDensity: VisualDensity.compact,
        ),
    ],
  );
}
