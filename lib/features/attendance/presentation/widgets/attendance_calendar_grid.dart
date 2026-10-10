import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_calendar_repository.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_calendar_legend.dart';

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
          children: weekdays
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      context.tr(day),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
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
            final entries = data.days[key] ?? const [];
            final statuses = entries.map((item) => item.status).toSet();
            final selected =
                selectedDate?.year == date.year &&
                selectedDate?.month == date.month &&
                selectedDate?.day == day;
            final today =
                now.year == date.year &&
                now.month == date.month &&
                now.day == day;
            final label = statuses.map(calendarStatusLabel).join(', ');
            return Semantics(
              button: true,
              selected: selected,
              label: context.tr('{value1}{value2}', {
                'value1': (key).toString(),
                'value2': (label.isEmpty ? '' : ', $label').toString(),
              }),
              child: InkWell(
                key: Key('calendar-day-$key'),
                onTap: () => onSelected(date),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 2,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: today && !selected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        child: Text(
                          context.tr('{value1}', {'value1': (day).toString()}),
                          style: TextStyle(
                            color: selected
                                ? Theme.of(context).colorScheme.onPrimary
                                : null,
                            fontWeight: today || selected
                                ? FontWeight.w700
                                : null,
                          ),
                        ),
                      ),
                      if (statuses.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 2,
                          runSpacing: 2,
                          children: statuses
                              .map(
                                (status) => Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: calendarStatusColor(status),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
