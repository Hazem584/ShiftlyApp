import 'package:equatable/equatable.dart';
import 'package:shiftly/features/attendance/domain/entities/calendar_attendance_status.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

class AttendanceCalendarEntry extends Equatable {
  const AttendanceCalendarEntry({
    required this.employeeMembershipId,
    required this.employee,
    required this.status,
    this.shift,
    this.attendance,
    this.leave,
  });

  final String employeeMembershipId;
  final ShiftEmployeeSummary employee;
  final CalendarAttendanceStatus status;
  final ShiftRecord? shift;
  final AttendanceRecordApi? attendance;
  final LeaveRequestRecord? leave;

  @override
  List<Object?> get props => [
    employeeMembershipId,
    employee,
    status,
    shift,
    attendance,
    leave,
  ];
}
