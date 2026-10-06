part of '../../shift_repository.dart';

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
