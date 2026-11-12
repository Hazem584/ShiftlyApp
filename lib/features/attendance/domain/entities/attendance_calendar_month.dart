import 'package:equatable/equatable.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/entities/attendance_calendar_entry.dart';

import 'attendance_month_control.dart';

class AttendanceCalendarMonth extends Equatable {
  const AttendanceCalendarMonth({
    required this.year,
    required this.month,
    required this.timezone,
    required this.days,
    this.nextRefreshAt,
    this.scheduledDates = const {},
    this.evaluatedAt,
    this.control,
  });

  final AttendanceMonthControl? control;
  final DateTime? nextRefreshAt, evaluatedAt;
  final Set<String> scheduledDates;
  final int year;
  final int month;
  final String timezone;
  final Map<String, List<AttendanceCalendarEntry>> days;

  List<AttendanceCalendarEntry> entriesFor(DateTime date) =>
      days[WorkspaceTime.localDateKey(
        year: date.year,
        month: date.month,
        day: date.day,
      )] ??
      const [];

  @override
  List<Object?> get props => [
    year,
    month,
    timezone,
    days,
    scheduledDates,
    nextRefreshAt,
    evaluatedAt,
    control,
  ];
}
