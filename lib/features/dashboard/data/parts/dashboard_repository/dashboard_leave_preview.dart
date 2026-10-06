part of '../../dashboard_repository.dart';

class DashboardLeavePreview extends Equatable {
  const DashboardLeavePreview({
    required this.id,
    required this.type,
    required this.startsAt,
    required this.endsAt,
    required this.reason,
    required this.employeeMembershipId,
    required this.employee,
    required this.createdAt,
  });

  final String id;
  final LeaveRequestType type;
  final DateTime startsAt;
  final DateTime endsAt;
  final String reason;
  final String employeeMembershipId;
  final DashboardPerson employee;
  final DateTime createdAt;

  factory DashboardLeavePreview.fromJson(Map<String, Object?> json) {
    final employee = ApiModelParser.map(json['employee'], 'employee');
    return DashboardLeavePreview(
      id: _uuid(json, 'id'),
      type: LeaveRequestType.parse(json['type']),
      startsAt: ApiModelParser.date(json, 'startsAt'),
      endsAt: ApiModelParser.date(json, 'endsAt'),
      reason: ApiModelParser.string(json, 'reason'),
      employeeMembershipId: _uuid(employee, 'employeeMembershipId'),
      employee: DashboardPerson.fromJson(employee),
      createdAt: ApiModelParser.date(json, 'createdAt'),
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    startsAt,
    endsAt,
    reason,
    employeeMembershipId,
    employee,
    createdAt,
  ];
}
