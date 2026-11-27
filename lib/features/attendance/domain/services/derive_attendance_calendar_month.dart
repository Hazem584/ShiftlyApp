import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/entities/attendance_calendar_entry.dart';
import 'package:shiftly/features/attendance/domain/entities/attendance_calendar_month.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/attendance/domain/services/attendance_calendar_entry_builder.dart';
import 'package:shiftly/features/attendance/domain/services/attendance_calendar_month_inputs.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';
import 'package:timezone/timezone.dart' as timezone;

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
  final validShifts = collectValidCalendarShifts(shifts, workspaceId);
  final att = collectValidCalendarAttendance(attendance, workspaceId);
  final approvedLeave = collectApprovedCalendarLeave(
    leaveRequests,
    workspaceId,
  );
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
    final dayEntries = _buildDayEntries(
      dayUtc: day.toUtc(),
      nextDayUtc: nextDay.toUtc(),
      key: key,
      validShifts: validShifts.values,
      approvedLeave: approvedLeave.values,
      validAttendance: att.attendance.values,
      templateDays: att.templateDays,
      nowUtc: nowUtc,
    );
    if (dayEntries.isNotEmpty) days[key] = dayEntries;
  }
  final upcoming =
      validShifts.values
          .map((e) => e.endsAt.toUtc())
          .where((e) => e.isAfter(nowUtc))
          .toList()
        ..sort();
  return AttendanceCalendarMonth(
    scheduledShifts: List.unmodifiable(validShifts.values),
    nextRefreshAt: upcoming.firstOrNull,
    scheduledDates: Set.unmodifiable(
      validShifts.values.map(
        (shift) => WorkspaceTime.dateKey(shift.startsAt, timezoneName),
      ),
    ),
    evaluatedAt: nowUtc,
    year: year,
    month: month,
    timezone: timezoneName,
    days: Map.unmodifiable(days),
  );
}

List<AttendanceCalendarEntry> _buildDayEntries({
  required DateTime dayUtc,
  required DateTime nextDayUtc,
  required String key,
  required Iterable<ShiftRecord> validShifts,
  required Iterable<LeaveRequestRecord> approvedLeave,
  required Iterable<AttendanceRecordApi> validAttendance,
  required Map<String, String> templateDays,
  required DateTime nowUtc,
}) {
  final dayShifts = validShifts
      .where((i) {
        final s = i.startsAt.toUtc();
        return !s.isBefore(dayUtc) && s.isBefore(nextDayUtc);
      })
      .toList(growable: false);
  final dayLeave = approvedLeave
      .where((i) => i.startsAt.isBefore(nextDayUtc) && i.endsAt.isAfter(dayUtc))
      .toList(growable: false);
  final dayAttendance = validAttendance
      .where(
        (i) => i.source == AttendanceSource.template
            ? templateDays[i.id] == key
            : dayShifts.any(
                (s) =>
                    s.id == i.shiftId &&
                    s.employeeMembershipId == i.employeeMembershipId,
              ),
      )
      .toList(growable: false);
  final employees = <String>{
    ...dayShifts.map((item) => item.employeeMembershipId),
    ...dayLeave.map((item) => item.employeeMembershipId),
    ...dayAttendance.map((item) => item.employeeMembershipId),
  };
  final entries = [
    for (final employeeId in employees)
      ?buildEmployeeCalendarEntry(
        employeeId: employeeId,
        dayShifts: dayShifts,
        dayLeave: dayLeave,
        dayAttendance: dayAttendance,
        nowUtc: nowUtc,
      ),
  ];
  entries.sort(
    (a, b) => a.employee.displayName.compareTo(b.employee.displayName),
  );
  return List.unmodifiable(entries);
}
