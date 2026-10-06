part of '../../dashboard_repository.dart';

class EmployeeDashboardLeave extends Equatable {
  const EmployeeDashboardLeave({
    required this.id,
    required this.type,
    required this.status,
    required this.startsAt,
    required this.endsAt,
    required this.reason,
    required this.createdAt,
    this.rejectionReason,
  });

  final String id;
  final LeaveRequestType type;
  final LeaveRequestStatus status;
  final DateTime startsAt;
  final DateTime endsAt;
  final String reason;
  final String? rejectionReason;
  final DateTime createdAt;

  factory EmployeeDashboardLeave.fromJson(Map<String, Object?> json) =>
      EmployeeDashboardLeave(
        id: _uuid(json, 'id'),
        type: LeaveRequestType.parse(json['type']),
        status: LeaveRequestStatus.parse(json['status']),
        startsAt: ApiModelParser.date(json, 'startsAt'),
        endsAt: ApiModelParser.date(json, 'endsAt'),
        reason: ApiModelParser.string(json, 'reason'),
        rejectionReason: ApiModelParser.optionalString(json['rejectionReason']),
        createdAt: ApiModelParser.date(json, 'createdAt'),
      );

  @override
  List<Object?> get props => [
    id,
    type,
    status,
    startsAt,
    endsAt,
    reason,
    rejectionReason,
    createdAt,
  ];
}
