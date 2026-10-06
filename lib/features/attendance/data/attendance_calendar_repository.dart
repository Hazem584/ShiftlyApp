import 'package:equatable/equatable.dart';
import 'package:shiftly/core/network/api_model_parser.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/data/attendance_repository.dart';
import 'package:shiftly/features/fixed_shifts/data/fixed_shift_repository.dart';
import 'package:shiftly/features/attendance/data/leave_request_repository.dart';
import 'package:shiftly/features/shifts/data/shift_repository.dart';
import 'package:timezone/timezone.dart' as timezone;

part 'parts/attendance_calendar_repository/calendar_attendance_status.dart';
part 'parts/attendance_calendar_repository/attendance_calendar_entry.dart';
part 'parts/attendance_calendar_repository/attendance_calendar_month.dart';
part 'parts/attendance_calendar_repository/attendance_calendar_repository.dart';
part 'parts/attendance_calendar_repository/api_attendance_calendar_repository.dart';

AttendanceCalendarMonth deriveAttendanceCalendarMonth({
  required String workspaceId,
  required String timezoneName,
  required int year,
  required int month,
  required List<ShiftRecord> shifts,
  required List<AttendanceRecordApi> attendance,
  required List<LeaveRequestRecord> leaveRequests,
  required DateTime nowUtc,
}) {
  final zone = WorkspaceTime.location(timezoneName);
  final monthStart = timezone.TZDateTime(zone, year, month);
  final monthEnd = timezone.TZDateTime(zone, year, month + 1);
  final validShifts = <String, ShiftRecord>{};
  for (final shift in shifts) {
    if (shift.workspaceId == workspaceId &&
        (shift.status == ShiftStatus.scheduled ||
            shift.status == ShiftStatus.completed)) {
      validShifts.putIfAbsent(shift.id, () => shift);
    }
  }
  final validAttendance = <String, AttendanceRecordApi>{};
  for (final record in attendance) {
    if (record.workspaceId == workspaceId &&
        record.source == AttendanceSource.legacyShift &&
        record.shift != null &&
        record.reviewStatus != AttendanceReviewStatus.rejected &&
        record.reviewStatus != AttendanceReviewStatus.unknown &&
        record.shift!.status != ShiftStatus.cancelled &&
        record.shift!.status != ShiftStatus.unknown) {
      validAttendance.putIfAbsent(record.id, () => record);
    }
  }
  final approvedLeave = <String, LeaveRequestRecord>{};
  for (final request in leaveRequests) {
    if (request.workspaceId == workspaceId &&
        request.status == LeaveRequestStatus.approved) {
      approvedLeave.putIfAbsent(request.id, () => request);
    }
  }

  final days = <String, List<AttendanceCalendarEntry>>{};
  for (
    var day = monthStart;
    day.isBefore(monthEnd);
    day = timezone.TZDateTime(zone, day.year, day.month, day.day + 1)
  ) {
    final nextDay = timezone.TZDateTime(zone, day.year, day.month, day.day + 1);
    final key = WorkspaceTime.localDateKey(
      year: day.year,
      month: day.month,
      day: day.day,
    );
    final dayShifts = validShifts.values
        .where((item) {
          final start = item.startsAt.toUtc();
          return !start.isBefore(day.toUtc()) &&
              start.isBefore(nextDay.toUtc());
        })
        .toList(growable: false);
    final dayLeave = approvedLeave.values
        .where(
          (item) =>
              item.startsAt.isBefore(nextDay.toUtc()) &&
              item.endsAt.isAfter(day.toUtc()),
        )
        .toList(growable: false);
    final employees = <String>{
      ...dayShifts.map((item) => item.employeeMembershipId),
      ...dayLeave.map((item) => item.employeeMembershipId),
    };
    final entries = <AttendanceCalendarEntry>[];
    for (final employeeId in employees) {
      final employeeShifts = dayShifts
          .where((item) => item.employeeMembershipId == employeeId)
          .toList();
      final employeeLeave = dayLeave
          .where((item) => item.employeeMembershipId == employeeId)
          .firstOrNull;
      final records = validAttendance.values
          .where(
            (item) =>
                item.employeeMembershipId == employeeId &&
                employeeShifts.any((shift) => shift.id == item.shiftId),
          )
          .toList();
      final attendanceRecord = records.isEmpty ? null : records.first;
      final lateRecord = records
          .where((item) => item.minutesLate > 0)
          .firstOrNull;
      final shift = employeeShifts.firstOrNull;
      final employee =
          attendanceRecord?.employee ??
          shift?.employee ??
          employeeLeave?.employee;
      if (employee == null) continue;
      CalendarAttendanceStatus? status;
      if (lateRecord != null) {
        status = CalendarAttendanceStatus.late;
      } else if (attendanceRecord != null) {
        status = CalendarAttendanceStatus.present;
      } else if (employeeLeave != null) {
        status = CalendarAttendanceStatus.leave;
      } else if (employeeShifts.any((item) => !item.endsAt.isAfter(nowUtc))) {
        status = CalendarAttendanceStatus.absent;
      }
      if (status != null) {
        entries.add(
          AttendanceCalendarEntry(
            employeeMembershipId: employeeId,
            employee: employee,
            status: status,
            shift: shift,
            attendance: lateRecord ?? attendanceRecord,
            leave: employeeLeave,
          ),
        );
      }
    }
    if (entries.isNotEmpty) {
      entries.sort(
        (a, b) => a.employee.displayName.compareTo(b.employee.displayName),
      );
      days[key] = List.unmodifiable(entries);
    }
  }
  return AttendanceCalendarMonth(
    year: year,
    month: month,
    timezone: timezoneName,
    days: Map.unmodifiable(days),
  );
}
