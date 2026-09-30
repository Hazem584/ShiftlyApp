import 'package:flutter/material.dart';

class AttendanceCalendarMonthHeader extends StatelessWidget {
  const AttendanceCalendarMonthHeader({
    required this.year,
    required this.month,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final int year;
  final int month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        key: const Key('calendar-previous-month'),
        onPressed: onPrevious,
        tooltip: 'Previous month',
        icon: const Icon(Icons.chevron_left_rounded),
      ),
      Expanded(
        child: Text(
          '${_months[month - 1]} $year',
          key: const Key('calendar-visible-month'),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      IconButton(
        key: const Key('calendar-next-month'),
        onPressed: onNext,
        tooltip: 'Next month',
        icon: const Icon(Icons.chevron_right_rounded),
      ),
    ],
  );
}
