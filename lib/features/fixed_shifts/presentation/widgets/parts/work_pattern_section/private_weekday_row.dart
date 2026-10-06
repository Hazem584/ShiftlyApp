part of '../../work_pattern_section.dart';

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow({required this.days});
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
