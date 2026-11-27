import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_calendar_repository.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_calendar_day_cell.dart';

class AttendanceCalendarGrid extends StatelessWidget {
  const AttendanceCalendarGrid({
    required this.data,
    required this.selectedDate,
    required this.onSelected,
    super.key,
  });

  final AttendanceCalendarMonth data;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    const weekdays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    final first = DateTime(data.year, data.month);
    final daysInMonth = DateTime(data.year, data.month + 1, 0).day;
    final leading = first.weekday % 7;
    final now = WorkspaceTime.inWorkspace(
      DateTime.now().toUtc(),
      data.timezone,
    );
    return Column(
      key: const Key('calendar-grid'),
      children: [
        Row(
          children: [
            for (final day in weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    context.tr(day),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 42,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: .82,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemBuilder: (context, index) {
            final day = index - leading + 1;
            if (day < 1 || day > daysInMonth) return const SizedBox.shrink();
            final date = DateTime(data.year, data.month, day);
            final key = WorkspaceTime.localDateKey(
              year: data.year,
              month: data.month,
              day: day,
            );
            final selected =
                selectedDate?.year == date.year &&
                selectedDate?.month == date.month &&
                selectedDate?.day == day;
            final today =
                now.year == date.year &&
                now.month == date.month &&
                now.day == day;
            return buildAttendanceCalendarDayCell(
              context: context,
              data: data,
              day: day,
              date: date,
              key: key,
              selected: selected,
              today: today,
              onSelected: onSelected,
            );
          },
        ),
      ],
    );
  }
}
