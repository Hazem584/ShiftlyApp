part of '../../dashboard_repository.dart';

class DashboardShiftPreview extends Equatable {
  const DashboardShiftPreview({
    required this.shiftId,
    required this.employeeMembershipId,
    required this.employee,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    this.attendance,
  });

  final String shiftId;
  final String employeeMembershipId;
  final DashboardPerson employee;
  final DateTime startsAt;
  final DateTime endsAt;
  final ShiftStatus status;
  final DashboardAttendance? attendance;

  factory DashboardShiftPreview.fromJson(Map<String, Object?> json) {
    final attendance = ApiModelParser.optionalMap(
      json['attendance'],
      'attendance',
    );
    return DashboardShiftPreview(
      shiftId: _uuid(json, 'shiftId'),
      employeeMembershipId: _uuid(json, 'employeeMembershipId'),
      employee: DashboardPerson.fromJson(
        ApiModelParser.map(json['employee'], 'employee'),
      ),
      startsAt: ApiModelParser.date(json, 'startsAt'),
      endsAt: ApiModelParser.date(json, 'endsAt'),
      status: ShiftStatus.parse(json['shiftStatus']),
      attendance: attendance == null
          ? null
          : DashboardAttendance.fromJson(attendance),
    );
  }

  @override
  List<Object?> get props => [
    shiftId,
    employeeMembershipId,
    employee,
    startsAt,
    endsAt,
    status,
    attendance,
  ];
}
