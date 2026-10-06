part of '../../attendance_calendar_repository.dart';

abstract interface class AttendanceCalendarRepository {
  Future<AttendanceCalendarMonth> loadMonth({
    required String workspaceId,
    required String timezone,
    required int year,
    required int month,
  });
}
