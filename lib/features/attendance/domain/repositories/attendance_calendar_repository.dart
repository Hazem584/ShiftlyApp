import 'package:shiftly/features/attendance/domain/entities/attendance_calendar_models.dart';

export 'package:shiftly/features/attendance/domain/entities/attendance_calendar_models.dart';

abstract interface class AttendanceCalendarRepository {
  Future<AttendanceCalendarMonth> loadMonth({
    required String workspaceId,
    required String timezone,
    required int year,
    required int month,
  });
}
