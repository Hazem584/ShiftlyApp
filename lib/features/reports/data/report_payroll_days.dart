import 'package:shiftly/features/attendance/domain/repositories/attendance_calendar_repository.dart';
import 'package:shiftly/features/reports/domain/attendance_report.dart';

import 'report_page_validator.dart';

Future<Map<String, ({int absent, int leave})>> fetchReportPayrollDays(
  AttendanceCalendarRepository calendar,
  String workspaceId,
  String timezone,
  ReportRange range,
  bool Function() isCurrent,
) async {
  final absent = <String, Set<String>>{}, leave = <String, Set<String>>{};
  for (
    var month = DateTime.utc(range.start.year, range.start.month);
    !month.isAfter(range.end);
    month = DateTime.utc(month.year, month.month + 1)
  ) {
    ReportPageValidator.checkCurrent(isCurrent);
    final result = await calendar.loadMonth(
      workspaceId: workspaceId,
      timezone: timezone,
      year: month.year,
      month: month.month,
    );
    ReportPageValidator.checkCurrent(isCurrent);
    if (result.year != month.year ||
        result.month != month.month ||
        result.timezone != timezone) {
      throw const FormatException('Invalid payroll calendar period');
    }
    for (final day in result.days.entries) {
      if (day.key.compareTo(range.startKey) < 0 ||
          day.key.compareTo(range.endKey) > 0) {
        continue;
      }
      for (final entry in day.value) {
        final id = entry.employeeMembershipId;
        switch (entry.status) {
          case CalendarAttendanceStatus.absent:
            absent.putIfAbsent(id, () => {}).add(day.key);
          case CalendarAttendanceStatus.leave:
            leave.putIfAbsent(id, () => {}).add(day.key);
          case CalendarAttendanceStatus.present:
          case CalendarAttendanceStatus.late:
            break;
        }
      }
    }
  }
  return {
    for (final id in {...absent.keys, ...leave.keys})
      id: (
        absent: (absent[id] ?? {}).difference(leave[id] ?? {}).length,
        leave: leave[id]?.length ?? 0,
      ),
  };
}
