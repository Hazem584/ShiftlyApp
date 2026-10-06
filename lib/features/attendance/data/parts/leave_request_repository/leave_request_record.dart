part of '../../leave_request_repository.dart';

class LeaveRequestRecord extends Equatable {
  const LeaveRequestRecord({
    required this.id,
    required this.workspaceId,
    required this.employeeMembershipId,
    required this.type,
    required this.status,
    required this.startsAt,
    required this.endsAt,
    required this.reason,
    required this.createdAt,
    required this.updatedAt,
    required this.employee,
    this.reviewedByMembershipId,
    this.reviewedAt,
    this.rejectionReason,
    this.cancelledAt,
  });

  final String id;
  final String workspaceId;
  final String employeeMembershipId;
  final LeaveRequestType type;
  final LeaveRequestStatus status;
  final DateTime startsAt;
  final DateTime endsAt;
  final String reason;
  final String? reviewedByMembershipId;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ShiftEmployeeSummary employee;

  bool get canReview => status == LeaveRequestStatus.pending;
  bool get canCancel => status == LeaveRequestStatus.pending;

  factory LeaveRequestRecord.fromJson(Map<String, Object?> json) =>
      LeaveRequestRecord(
        id: ApiModelParser.string(json, 'id'),
        workspaceId: ApiModelParser.string(json, 'workspaceId'),
        employeeMembershipId: ApiModelParser.string(
          json,
          'employeeMembershipId',
        ),
        type: LeaveRequestType.parse(json['type']),
        status: LeaveRequestStatus.parse(json['status']),
        startsAt: ApiModelParser.date(json, 'startsAt'),
        endsAt: ApiModelParser.date(json, 'endsAt'),
        reason: ApiModelParser.string(json, 'reason'),
        reviewedByMembershipId: ApiModelParser.optionalString(
          json['reviewedByMembershipId'],
        ),
        reviewedAt: ApiModelParser.optionalDate(json['reviewedAt']),
        rejectionReason: ApiModelParser.optionalString(json['rejectionReason']),
        cancelledAt: ApiModelParser.optionalDate(json['cancelledAt']),
        createdAt: ApiModelParser.date(json, 'createdAt'),
        updatedAt: ApiModelParser.date(json, 'updatedAt'),
        employee: ShiftEmployeeSummary.fromJson(
          ApiModelParser.map(json['employee'], 'employee'),
        ),
      );

  @override
  List<Object?> get props => [
    id,
    workspaceId,
    employeeMembershipId,
    type,
    status,
    startsAt,
    endsAt,
    reason,
    reviewedByMembershipId,
    reviewedAt,
    rejectionReason,
    cancelledAt,
    createdAt,
    updatedAt,
    employee,
  ];
}
