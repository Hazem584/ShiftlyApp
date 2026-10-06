part of '../../attendance_calendar_repository.dart';

class AttendanceCalendarMonth extends Equatable {
  const AttendanceCalendarMonth({
    required this.year,
    required this.month,
    required this.timezone,
    required this.days,
  });

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
  List<Object?> get props => [year, month, timezone, days];
}
