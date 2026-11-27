import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_calendar_repository.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_calendar_legend.dart';

Widget buildAttendanceCalendarDayCell({
  required BuildContext context,
  required AttendanceCalendarMonth data,
  required int day,
  required DateTime date,
  required String key,
  required bool selected,
  required bool today,
  required ValueChanged<DateTime> onSelected,
}) {
  final entries = data.days[key] ?? const [];
  final statuses = entries.map((item) => item.status).toSet();
  final label = statuses.map(calendarStatusLabel).join(', ');
  final primary = Theme.of(context).colorScheme.primary;
  return Semantics(
    button: true,
    selected: selected,
    label: context.tr('{value1}{value2}', {
      'value1': key,
      'value2': label.isEmpty ? '' : ', $label',
    }),
    child: InkWell(
      key: Key('calendar-day-$key'),
      onTap: () => onSelected(date),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: today && !selected ? Border.all(color: primary) : null,
        ),
        child: _buildDayCellChildren(
          context: context,
          day: day,
          date: date,
          key: key,
          selected: selected,
          today: today,
          isEmpty: entries.isEmpty,
          scheduledDates: data.scheduledDates,
          statuses: statuses,
        ),
      ),
    ),
  );
}

Widget _buildDayCellChildren({
  required BuildContext context,
  required int day,
  required DateTime date,
  required String key,
  required bool selected,
  required bool today,
  required bool isEmpty,
  required Set<String> scheduledDates,
  required Set<CalendarAttendanceStatus> statuses,
}) => Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Flexible(
      child: FittedBox(
        child: Text(
          context.tr('{value1}', {'value1': '$day'}),
          style: TextStyle(
            color: selected ? Theme.of(context).colorScheme.onPrimary : null,
            fontWeight: today || selected ? FontWeight.w700 : null,
          ),
        ),
      ),
    ),
    if (date.weekday == DateTime.friday &&
        isEmpty &&
        !scheduledDates.contains(key))
      Text(
        context.tr('Off'),
        style: TextStyle(
          fontSize: 9,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    if (statuses.isNotEmpty) ...[
      const SizedBox(height: 3),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 2,
        runSpacing: 2,
        children: [
          for (final status in statuses)
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: calendarStatusColor(status),
              ),
            ),
        ],
      ),
    ],
  ],
);
