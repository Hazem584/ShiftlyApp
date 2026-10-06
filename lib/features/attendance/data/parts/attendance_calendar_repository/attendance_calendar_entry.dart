part of '../../attendance_calendar_repository.dart';

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
