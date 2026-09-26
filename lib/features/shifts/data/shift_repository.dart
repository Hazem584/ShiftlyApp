import 'package:equatable/equatable.dart';
import 'package:shiftly/core/network/api_model_parser.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';

enum ShiftStatus {
  scheduled,
  cancelled,
  completed,
  unknown;

  static ShiftStatus parse(Object? value) => switch (value) {
    'SCHEDULED' => scheduled,
    'CANCELLED' => cancelled,
    'COMPLETED' => completed,
    _ => unknown,
  };

  String? get apiValue => switch (this) {
    scheduled => 'SCHEDULED',
    cancelled => 'CANCELLED',
    completed => 'COMPLETED',
    unknown => null,
  };
}

enum AttendanceReviewStatus {
  pending,
  approved,
  rejected,
  unknown;

  static AttendanceReviewStatus parse(Object? value) => switch (value) {
    'PENDING' => pending,
    'APPROVED' => approved,
    'REJECTED' => rejected,
    _ => unknown,
  };
}

class ShiftEmployeeSummary extends Equatable {
  const ShiftEmployeeSummary({
    required this.membershipId,
    required this.profileId,
    required this.role,
    required this.membershipStatus,
    this.fullName,
    this.email,
    this.phone,
    this.avatarUrl,
    this.jobTitle,
    this.joinedAt,
  });

  final String membershipId;
  final String profileId;
  final WorkspaceRole role;
  final MembershipStatus membershipStatus;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? jobTitle;
  final DateTime? joinedAt;

  String get displayName => fullName ?? email ?? 'Unnamed employee';

  factory ShiftEmployeeSummary.fromJson(Map<String, Object?> json) =>
      ShiftEmployeeSummary(
        membershipId: ApiModelParser.string(json, 'id'),
        profileId: ApiModelParser.string(json, 'profileId'),
        role: WorkspaceRole.parse(json['role']),
        membershipStatus: MembershipStatus.parse(json['status']),
        fullName: ApiModelParser.optionalString(json['fullName']),
        email: ApiModelParser.optionalString(json['email']),
        phone: ApiModelParser.optionalString(json['phone']),
        avatarUrl: ApiModelParser.optionalString(json['avatarUrl']),
        jobTitle: ApiModelParser.optionalString(json['jobTitle']),
        joinedAt: ApiModelParser.optionalDate(json['joinedAt']),
      );

  @override
  List<Object?> get props => [
    membershipId,
    profileId,
    role,
    membershipStatus,
    fullName,
    email,
    phone,
    avatarUrl,
    jobTitle,
    joinedAt,
  ];
}

class ShiftAttendanceSummary extends Equatable {
  const ShiftAttendanceSummary({
    required this.id,
    required this.clockInAt,
    required this.reviewStatus,
    required this.minutesLate,
    this.clockOutAt,
    this.workedMinutes,
  });

  final String id;
  final DateTime clockInAt;
  final DateTime? clockOutAt;
  final AttendanceReviewStatus reviewStatus;
  final int minutesLate;
  final int? workedMinutes;

  factory ShiftAttendanceSummary.fromJson(Map<String, Object?> json) =>
      ShiftAttendanceSummary(
        id: ApiModelParser.string(json, 'id'),
        clockInAt: ApiModelParser.date(json, 'clockInAt'),
        clockOutAt: ApiModelParser.optionalDate(json['clockOutAt']),
        reviewStatus: AttendanceReviewStatus.parse(json['reviewStatus']),
        minutesLate: ApiModelParser.integer(json, 'minutesLate'),
        workedMinutes: ApiModelParser.optionalInteger(json['workedMinutes']),
      );

  @override
  List<Object?> get props => [
    id,
    clockInAt,
    clockOutAt,
    reviewStatus,
    minutesLate,
    workedMinutes,
  ];
}

class ShiftRecord extends Equatable {
  const ShiftRecord({
    required this.id,
    required this.workspaceId,
    required this.employeeMembershipId,
    required this.createdByMembershipId,
    required this.startsAt,
    required this.endsAt,
    required this.breakMinutes,
    required this.graceMinutes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.employee,
    this.notes,
    this.attendance,
  });

  final String id;
  final String workspaceId;
  final String employeeMembershipId;
  final String createdByMembershipId;
  final DateTime startsAt;
  final DateTime endsAt;
  final int breakMinutes;
  final int graceMinutes;
  final String? notes;
  final ShiftStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ShiftEmployeeSummary employee;
  final ShiftAttendanceSummary? attendance;

  bool get canManage => status == ShiftStatus.scheduled;
  bool get canClockIn => status == ShiftStatus.scheduled && attendance == null;
  bool get canClockOut =>
      status == ShiftStatus.scheduled &&
      attendance != null &&
      attendance!.clockOutAt == null &&
      attendance!.reviewStatus != AttendanceReviewStatus.rejected &&
      attendance!.reviewStatus != AttendanceReviewStatus.unknown;

  ShiftRecord copyWith({
    ShiftStatus? status,
    ShiftAttendanceSummary? attendance,
  }) => ShiftRecord(
    id: id,
    workspaceId: workspaceId,
    employeeMembershipId: employeeMembershipId,
    createdByMembershipId: createdByMembershipId,
    startsAt: startsAt,
    endsAt: endsAt,
    breakMinutes: breakMinutes,
    graceMinutes: graceMinutes,
    notes: notes,
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: updatedAt,
    employee: employee,
    attendance: attendance ?? this.attendance,
  );

  factory ShiftRecord.fromJson(Map<String, Object?> json) {
    final employee = ApiModelParser.map(json['employee'], 'employee');
    final attendance = ApiModelParser.optionalMap(
      json['attendance'],
      'attendance',
    );
    return ShiftRecord(
      id: ApiModelParser.string(json, 'id'),
      workspaceId: ApiModelParser.string(json, 'workspaceId'),
      employeeMembershipId: ApiModelParser.string(json, 'employeeMembershipId'),
      createdByMembershipId: ApiModelParser.string(
        json,
        'createdByMembershipId',
      ),
      startsAt: ApiModelParser.date(json, 'startsAt'),
      endsAt: ApiModelParser.date(json, 'endsAt'),
      breakMinutes: ApiModelParser.integer(json, 'breakMinutes'),
      graceMinutes: ApiModelParser.integer(json, 'graceMinutes'),
      notes: ApiModelParser.optionalString(json['notes']),
      status: ShiftStatus.parse(json['status']),
      createdAt: ApiModelParser.date(json, 'createdAt'),
      updatedAt: ApiModelParser.date(json, 'updatedAt'),
      employee: ShiftEmployeeSummary.fromJson(employee),
      attendance: attendance == null
          ? null
          : ShiftAttendanceSummary.fromJson(attendance),
    );
  }

  @override
  List<Object?> get props => [
    id,
    workspaceId,
    employeeMembershipId,
    createdByMembershipId,
    startsAt,
    endsAt,
    breakMinutes,
    graceMinutes,
    notes,
    status,
    createdAt,
    updatedAt,
    employee,
    attendance,
  ];
}

class ShiftPage {
  const ShiftPage({required this.data, required this.pagination});
  final List<ShiftRecord> data;
  final ApiPagination pagination;
}

class ShiftQuery {
  const ShiftQuery({
    this.page = 1,
    this.limit = 20,
    this.from,
    this.to,
    this.employeeMembershipId,
    this.status,
  });
  final int page;
  final int limit;
  final DateTime? from;
  final DateTime? to;
  final String? employeeMembershipId;
  final ShiftStatus? status;

  Map<String, Object?> toQuery({bool includeEmployee = true}) => {
    'page': page,
    'limit': limit,
    if (from != null) 'from': from!.toUtc().toIso8601String(),
    if (to != null) 'to': to!.toUtc().toIso8601String(),
    if (includeEmployee && employeeMembershipId != null)
      'employeeMembershipId': employeeMembershipId,
    if (status?.apiValue != null) 'status': status!.apiValue,
  };

  ShiftQuery copyWith({int? page}) => ShiftQuery(
    page: page ?? this.page,
    limit: limit,
    from: from,
    to: to,
    employeeMembershipId: employeeMembershipId,
    status: status,
  );
}

class CreateShiftInput {
  const CreateShiftInput({
    required this.employeeMembershipId,
    required this.startsAt,
    required this.endsAt,
    required this.breakMinutes,
    required this.graceMinutes,
    this.notes,
  });
  final String employeeMembershipId;
  final DateTime startsAt;
  final DateTime endsAt;
  final int breakMinutes;
  final int graceMinutes;
  final String? notes;

  Map<String, Object?> toJson() => {
    'employeeMembershipId': employeeMembershipId,
    'startsAt': startsAt.toUtc().toIso8601String(),
    'endsAt': endsAt.toUtc().toIso8601String(),
    'breakMinutes': breakMinutes,
    'graceMinutes': graceMinutes,
    if (notes?.trim().isNotEmpty == true) 'notes': notes!.trim(),
  };
}

class UpdateShiftInput {
  const UpdateShiftInput({
    this.employeeMembershipId,
    this.startsAt,
    this.endsAt,
    this.breakMinutes,
    this.graceMinutes,
    this.notes,
  });
  final String? employeeMembershipId;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int? breakMinutes;
  final int? graceMinutes;
  final String? notes;

  Map<String, Object?> toJson() => {
    if (employeeMembershipId != null)
      'employeeMembershipId': employeeMembershipId,
    if (startsAt != null) 'startsAt': startsAt!.toUtc().toIso8601String(),
    if (endsAt != null) 'endsAt': endsAt!.toUtc().toIso8601String(),
    if (breakMinutes != null) 'breakMinutes': breakMinutes,
    if (graceMinutes != null) 'graceMinutes': graceMinutes,
    if (notes != null) 'notes': notes!.trim(),
  };
}

abstract interface class ShiftRepository {
  Future<ShiftPage> listWorkspaceShifts(String workspaceId, ShiftQuery query);
  Future<ShiftRecord> getWorkspaceShift(String workspaceId, String shiftId);
  Future<ShiftRecord> createShift(String workspaceId, CreateShiftInput input);
  Future<ShiftRecord> updateShift(
    String workspaceId,
    String shiftId,
    UpdateShiftInput input,
  );
  Future<ShiftRecord> cancelShift(String workspaceId, String shiftId);
  Future<ShiftPage> listMyShifts(ShiftQuery query);
  Future<ShiftRecord> getMyShift(String shiftId);
}
