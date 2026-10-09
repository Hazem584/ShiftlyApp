import 'package:flutter/material.dart';

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
            const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][day],
          ),
          visualDensity: VisualDensity.compact,
        ),
    ],
  );
}
