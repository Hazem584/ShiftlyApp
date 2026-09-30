import 'package:flutter/material.dart';
import 'package:shiftly/features/attendance/data/attendance_calendar_repository.dart';

Color calendarStatusColor(CalendarAttendanceStatus status) => switch (status) {
  CalendarAttendanceStatus.present => const Color(0xFF12A150),
  CalendarAttendanceStatus.absent => const Color(0xFFE53935),
  CalendarAttendanceStatus.late => const Color(0xFFE9A900),
  CalendarAttendanceStatus.leave => const Color(0xFF5B6EF5),
};

String calendarStatusLabel(CalendarAttendanceStatus status) => switch (status) {
  CalendarAttendanceStatus.present => 'Present',
  CalendarAttendanceStatus.absent => 'Absent',
  CalendarAttendanceStatus.late => 'Late',
  CalendarAttendanceStatus.leave => 'Leave',
};

class AttendanceCalendarLegend extends StatelessWidget {
  const AttendanceCalendarLegend({super.key});

  @override
  Widget build(BuildContext context) => Wrap(
    key: const Key('calendar-legend'),
    spacing: 14,
    runSpacing: 8,
    children: CalendarAttendanceStatus.values
        .map(
          (status) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: calendarStatusColor(status),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(calendarStatusLabel(status)),
            ],
          ),
        )
        .toList(growable: false),
  );
}
