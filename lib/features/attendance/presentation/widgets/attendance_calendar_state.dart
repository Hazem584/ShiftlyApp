import 'package:flutter/material.dart';
import 'package:shiftly/core/widgets/empty_state.dart';

class AttendanceCalendarState extends StatelessWidget {
  const AttendanceCalendarState({super.key});
  @override
  Widget build(BuildContext context) => const EmptyState(
    icon: Icons.calendar_month_outlined,
    title: 'Calendar view',
    message:
        'The team attendance calendar will be connected in a future sprint.',
  );
}
