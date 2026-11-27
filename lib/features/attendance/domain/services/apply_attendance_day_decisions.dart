import 'package:shiftly/features/attendance/domain/entities/attendance_calendar_entry.dart';
import 'package:shiftly/features/attendance/domain/entities/attendance_calendar_month.dart';
import 'package:shiftly/features/attendance/domain/entities/attendance_month_control.dart';
import 'package:shiftly/features/attendance/domain/entities/calendar_attendance_status.dart';

AttendanceCalendarMonth applyAttendanceDayDecisions(
  AttendanceCalendarMonth month,
  AttendanceMonthControl control,
) {
  final days = month.days.map((k, v) => MapEntry(k, [...v]));
  if (control.closed) {
    for (final day in control.approvedDays) {
      final entries = days.putIfAbsent(day.date, () => []);
      final index = entries.indexWhere(
        (e) => e.employeeMembershipId == day.employeeMembershipId,
      );
      final previous = index < 0 ? null : entries[index];
      final employee = day.employee ?? previous?.employee;
      final status = _parseCalendarStatus(day.status);
      if (employee == null || status == null) continue;
      _upsertEntry(
        entries,
        index,
        AttendanceCalendarEntry(
          employeeMembershipId: day.employeeMembershipId,
          employee: employee,
          status: status,
          shift: previous?.shift,
          attendance: previous?.attendance,
          leave: previous?.leave,
        ),
      );
    }
  }
  for (final decision in control.overrides) {
    final entries = days.putIfAbsent(decision.date, () => []);
    final index = entries.indexWhere(
      (e) => e.employeeMembershipId == decision.employeeMembershipId,
    );
    final previous = index < 0 ? null : entries[index];
    final status =
        _parseCalendarStatus(decision.status) ?? previous?.status;
    if (status == null) continue;
    _upsertEntry(
      entries,
      index,
      AttendanceCalendarEntry(
        employeeMembershipId: decision.employeeMembershipId,
        employee: previous?.employee ?? decision.employee,
        status: status,
        shift: previous?.shift,
        attendance: previous?.attendance,
        leave: previous?.leave,
        decisionReason: decision.status == 'AUTO' ? null : decision.reason,
        decisionRevision: decision.revision,
      ),
    );
  }
  return AttendanceCalendarMonth(
    scheduledShifts: month.scheduledShifts,
    year: month.year,
    month: month.month,
    timezone: month.timezone,
    days: days,
    control: control,
    evaluatedAt: month.evaluatedAt,
    nextRefreshAt: month.nextRefreshAt,
    scheduledDates: month.scheduledDates,
  );
}

CalendarAttendanceStatus? _parseCalendarStatus(String status) =>
    switch (status) {
      'PRESENT' => CalendarAttendanceStatus.present,
      'LATE' => CalendarAttendanceStatus.late,
      'ABSENT' => CalendarAttendanceStatus.absent,
      'LEAVE' => CalendarAttendanceStatus.leave,
      _ => null,
    };

void _upsertEntry(
  List<AttendanceCalendarEntry> entries,
  int index,
  AttendanceCalendarEntry entry,
) => index < 0 ? entries.add(entry) : entries[index] = entry;
