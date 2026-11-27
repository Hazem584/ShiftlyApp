import 'package:shiftly/features/attendance/domain/entities/attendance_calendar_entry.dart';
import 'package:shiftly/features/attendance/domain/entities/calendar_attendance_status.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

AttendanceCalendarEntry? buildEmployeeCalendarEntry({
  required String employeeId,
  required List<ShiftRecord> dayShifts,
  required List<LeaveRequestRecord> dayLeave,
  required List<AttendanceRecordApi> dayAttendance,
  required DateTime nowUtc,
}) {
  final employeeShifts = dayShifts
      .where((item) => item.employeeMembershipId == employeeId)
      .toList();
  final employeeLeave = dayLeave
      .where((item) => item.employeeMembershipId == employeeId)
      .firstOrNull;
  final records = dayAttendance
      .where((item) => item.employeeMembershipId == employeeId)
      .toList();
  final attendanceRecord = records.isEmpty ? null : records.first;
  final lateRecord = records
      .where(
        (item) =>
            item.minutesLate > 0 ||
            item.clockInClassification == AttendanceClassification.late,
      )
      .firstOrNull;
  final selectedRecord = lateRecord ?? attendanceRecord;
  final shift = selectedRecord == null
      ? employeeShifts.firstOrNull
      : employeeShifts
            .where((item) => item.id == selectedRecord.shiftId)
            .firstOrNull;
  final employee =
      attendanceRecord?.employee ?? shift?.employee ?? employeeLeave?.employee;
  if (employee == null) return null;
  CalendarAttendanceStatus? status;
  if (lateRecord != null) {
    status = CalendarAttendanceStatus.late;
  } else if (attendanceRecord != null) {
    status = CalendarAttendanceStatus.present;
  } else if (employeeLeave != null) {
    status = CalendarAttendanceStatus.leave;
  } else if (employeeShifts.isNotEmpty &&
      employeeShifts.every((item) => !item.endsAt.isAfter(nowUtc))) {
    status = CalendarAttendanceStatus.absent;
  }
  if (status == null) return null;
  return AttendanceCalendarEntry(
    employeeMembershipId: employeeId,
    employee: employee,
    status: status,
    shift: shift,
    attendance: lateRecord ?? attendanceRecord,
    leave: employeeLeave,
  );
}
