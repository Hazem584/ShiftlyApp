import 'package:equatable/equatable.dart';
import 'package:shiftly/core/network/api_model_parser.dart';
import 'package:shiftly/features/shifts/data/shift_repository.dart';

enum LeaveRequestType {
  annualLeave,
  sickLeave,
  emergencyLeave,
  earlyLeave,
  other,
  unknown;

  static LeaveRequestType parse(Object? value) => switch (value) {
    'ANNUAL_LEAVE' => annualLeave,
    'SICK_LEAVE' => sickLeave,
    'EMERGENCY_LEAVE' => emergencyLeave,
    'EARLY_LEAVE' => earlyLeave,
    'OTHER' => other,
    _ => unknown,
  };

  String? get apiValue => switch (this) {
    annualLeave => 'ANNUAL_LEAVE',
    sickLeave => 'SICK_LEAVE',
    emergencyLeave => 'EMERGENCY_LEAVE',
    earlyLeave => 'EARLY_LEAVE',
    other => 'OTHER',
    unknown => null,
  };
}

enum LeaveRequestStatus {
  pending,
  approved,
  rejected,
  cancelled,
  unknown;

  static LeaveRequestStatus parse(Object? value) => switch (value) {
    'PENDING' => pending,
    'APPROVED' => approved,
    'REJECTED' => rejected,
    'CANCELLED' => cancelled,
    _ => unknown,
  };

  String? get apiValue => switch (this) {
    pending => 'PENDING',
    approved => 'APPROVED',
    rejected => 'REJECTED',
    cancelled => 'CANCELLED',
    unknown => null,
  };
}

enum LeaveReviewDecision { approved, rejected }

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

class LeaveRequestPage {
  const LeaveRequestPage({required this.data, required this.pagination});
  final List<LeaveRequestRecord> data;
  final ApiPagination pagination;
}

class LeaveRequestQuery {
  const LeaveRequestQuery({
    this.page = 1,
    this.limit = 20,
    this.from,
    this.to,
    this.type,
    this.status,
    this.employeeMembershipId,
    this.search,
  });

  final int page;
  final int limit;
  final DateTime? from;
  final DateTime? to;
  final LeaveRequestType? type;
  final LeaveRequestStatus? status;
  final String? employeeMembershipId;
  final String? search;

  Map<String, Object?> toQuery({required bool manager}) => {
    'page': page,
    'limit': limit,
    if (from != null) 'from': from!.toUtc().toIso8601String(),
    if (to != null) 'to': to!.toUtc().toIso8601String(),
    if (type?.apiValue != null) 'type': type!.apiValue,
    if (status?.apiValue != null) 'status': status!.apiValue,
    if (manager && employeeMembershipId != null)
      'employeeMembershipId': employeeMembershipId,
    if (manager && search?.trim().isNotEmpty == true) 'search': search!.trim(),
  };

  LeaveRequestQuery copyWith({int? page}) => LeaveRequestQuery(
    page: page ?? this.page,
    limit: limit,
    from: from,
    to: to,
    type: type,
    status: status,
    employeeMembershipId: employeeMembershipId,
    search: search,
  );
}

class CreateLeaveRequestInput {
  const CreateLeaveRequestInput({
    required this.type,
    required this.startsAt,
    required this.endsAt,
    required this.reason,
  });

  final LeaveRequestType type;
  final DateTime startsAt;
  final DateTime endsAt;
  final String reason;

  Map<String, Object?> toJson(String workspaceId) => {
    'workspaceId': workspaceId,
    'type': type.apiValue,
    'startsAt': startsAt.toUtc().toIso8601String(),
    'endsAt': endsAt.toUtc().toIso8601String(),
    'reason': reason.trim(),
  };
}

abstract interface class LeaveRequestRepository {
  Future<LeaveRequestRecord> create(
    String workspaceId,
    CreateLeaveRequestInput input,
  );
  Future<LeaveRequestPage> listMine(
    String workspaceId,
    LeaveRequestQuery query,
  );
  Future<LeaveRequestRecord> getMine(String requestId);
  Future<LeaveRequestRecord> cancelMine(String requestId);
  Future<LeaveRequestPage> listWorkspace(
    String workspaceId,
    LeaveRequestQuery query,
  );
  Future<LeaveRequestRecord> getWorkspace(String workspaceId, String requestId);
  Future<LeaveRequestRecord> review(
    String workspaceId,
    String requestId,
    LeaveReviewDecision decision, {
    String? rejectionReason,
  });
}
