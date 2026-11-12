import '../entities/attendance_calendar_entry.dart';
import '../entities/attendance_calendar_month.dart';
import '../entities/attendance_month_control.dart';
import '../entities/calendar_attendance_status.dart';

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
      final status = switch (day.status) {
        'PRESENT' => CalendarAttendanceStatus.present,
        'LATE' => CalendarAttendanceStatus.late,
        'ABSENT' => CalendarAttendanceStatus.absent,
        'LEAVE' => CalendarAttendanceStatus.leave,
        _ => null,
      };
      if (employee == null || status == null) continue;
      final entry = AttendanceCalendarEntry(
        employeeMembershipId: day.employeeMembershipId,
        employee: employee,
        status: status,
        shift: previous?.shift,
        attendance: previous?.attendance,
        leave: previous?.leave,
      );
      if (index < 0) {
        entries.add(entry);
      } else {
        entries[index] = entry;
      }
    }
  }
  for (final decision in control.overrides) {
    final entries = days.putIfAbsent(decision.date, () => []);
    final index = entries.indexWhere(
      (e) => e.employeeMembershipId == decision.employeeMembershipId,
    );
    final previous = index < 0 ? null : entries[index];
    final status = switch (decision.status) {
      'PRESENT' => CalendarAttendanceStatus.present,
      'LATE' => CalendarAttendanceStatus.late,
      'ABSENT' => CalendarAttendanceStatus.absent,
      'LEAVE' => CalendarAttendanceStatus.leave,
      _ => previous?.status,
    };
    if (status == null) continue;
    final entry = AttendanceCalendarEntry(
      employeeMembershipId: decision.employeeMembershipId,
      employee: previous?.employee ?? decision.employee,
      status: status,
      shift: previous?.shift,
      attendance: previous?.attendance,
      leave: previous?.leave,
      decisionReason: decision.status == 'AUTO' ? null : decision.reason,
      decisionRevision: decision.revision,
    );
    if (index < 0) {
      entries.add(entry);
    } else {
      entries[index] = entry;
    }
  }
  return AttendanceCalendarMonth(
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
