import 'package:equatable/equatable.dart';
import 'package:shiftly/core/network/api_model_parser.dart';
import 'package:shiftly/features/shifts/data/shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/data/fixed_shift_repository.dart';

enum AttendanceReviewDecision { approved, rejected }

class AttendanceShiftSummary extends Equatable {
  const AttendanceShiftSummary({
    required this.id,
    required this.startsAt,
    required this.endsAt,
    required this.breakMinutes,
    required this.graceMinutes,
    required this.status,
    this.notes,
  });
  final String id;
  final DateTime startsAt;
  final DateTime endsAt;
  final int breakMinutes;
  final int graceMinutes;
  final String? notes;
  final ShiftStatus status;

  factory AttendanceShiftSummary.fromJson(Map<String, Object?> json) =>
      AttendanceShiftSummary(
        id: ApiModelParser.string(json, 'id'),
        startsAt: ApiModelParser.date(json, 'startsAt'),
        endsAt: ApiModelParser.date(json, 'endsAt'),
        breakMinutes: ApiModelParser.integer(json, 'breakMinutes'),
        graceMinutes: ApiModelParser.integer(json, 'graceMinutes'),
        notes: ApiModelParser.optionalString(json['notes']),
        status: ShiftStatus.parse(json['status']),
      );

  @override
  List<Object?> get props => [
    id,
    startsAt,
    endsAt,
    breakMinutes,
    graceMinutes,
    notes,
    status,
  ];
}

class AttendanceRecordApi extends Equatable {
  const AttendanceRecordApi({
    required this.id,
    required this.workspaceId,
    required this.shiftId,
    required this.employeeMembershipId,
    required this.clockInAt,
    required this.reviewStatus,
    required this.minutesLate,
    required this.createdAt,
    required this.updatedAt,
    this.source = AttendanceSource.legacyShift,
    this.shift,
    required this.employee,
    this.clockOutAt,
    this.reviewedByMembershipId,
    this.reviewedAt,
    this.rejectionReason,
    this.workedMinutes,
    this.shiftTemplateId,
    this.templateName,
    this.workspaceTimezone,
    this.operationalDate,
    this.scheduledStartAt,
    this.scheduledEndAt,
    this.graceMinutesUsed,
    this.minimumWorkMinutesUsed,
    this.clockInClassification,
  });

  final String id;
  final String workspaceId;
  final String? shiftId;
  final AttendanceSource source;
  final String? shiftTemplateId;
  final String? templateName;
  final String? workspaceTimezone;
  final String? operationalDate;
  final DateTime? scheduledStartAt;
  final DateTime? scheduledEndAt;
  final int? graceMinutesUsed;
  final int? minimumWorkMinutesUsed;
  final AttendanceClassification? clockInClassification;
  final String employeeMembershipId;
  final DateTime clockInAt;
  final DateTime? clockOutAt;
  final AttendanceReviewStatus reviewStatus;
  final String? reviewedByMembershipId;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final int minutesLate;
  final int? workedMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AttendanceShiftSummary? shift;
  final ShiftEmployeeSummary employee;

  bool get isOpen => clockOutAt == null;
  bool get canReview =>
      reviewStatus == AttendanceReviewStatus.pending &&
      source != AttendanceSource.unknown;

  factory AttendanceRecordApi.fromJson(
    Map<String, Object?> json,
  ) => AttendanceRecordApi(
    id: ApiModelParser.string(json, 'id'),
    workspaceId: ApiModelParser.string(json, 'workspaceId'),
    shiftId: ApiModelParser.optionalString(json['shiftId']),
    source: AttendanceSource.parse(json['source']),
    shiftTemplateId: ApiModelParser.optionalString(json['shiftTemplateId']),
    templateName: ApiModelParser.optionalString(json['templateName']),
    workspaceTimezone: ApiModelParser.optionalString(json['workspaceTimezone']),
    operationalDate: ApiModelParser.optionalString(json['operationalDate']),
    scheduledStartAt: ApiModelParser.optionalDate(json['scheduledStartAt']),
    scheduledEndAt: ApiModelParser.optionalDate(json['scheduledEndAt']),
    graceMinutesUsed: ApiModelParser.optionalInteger(json['graceMinutesUsed']),
    minimumWorkMinutesUsed: ApiModelParser.optionalInteger(
      json['minimumWorkMinutesUsed'],
    ),
    clockInClassification: json['clockInClassification'] == null
        ? null
        : AttendanceClassification.parse(json['clockInClassification']),
    employeeMembershipId: ApiModelParser.string(json, 'employeeMembershipId'),
    clockInAt: ApiModelParser.date(json, 'clockInAt'),
    clockOutAt: ApiModelParser.optionalDate(json['clockOutAt']),
    reviewStatus: AttendanceReviewStatus.parse(json['reviewStatus']),
    reviewedByMembershipId: ApiModelParser.optionalString(
      json['reviewedByMembershipId'],
    ),
    reviewedAt: ApiModelParser.optionalDate(json['reviewedAt']),
    rejectionReason: ApiModelParser.optionalString(json['rejectionReason']),
    minutesLate: ApiModelParser.integer(json, 'minutesLate'),
    workedMinutes: ApiModelParser.optionalInteger(json['workedMinutes']),
    createdAt: ApiModelParser.date(json, 'createdAt'),
    updatedAt: ApiModelParser.date(json, 'updatedAt'),
    shift: json['shift'] == null
        ? null
        : AttendanceShiftSummary.fromJson(
            ApiModelParser.map(json['shift'], 'shift'),
          ),
    employee: ShiftEmployeeSummary.fromJson(
      ApiModelParser.map(json['employee'], 'employee'),
    ),
  );

  @override
  List<Object?> get props => [
    id,
    workspaceId,
    shiftId,
    source,
    shiftTemplateId,
    templateName,
    workspaceTimezone,
    operationalDate,
    scheduledStartAt,
    scheduledEndAt,
    graceMinutesUsed,
    minimumWorkMinutesUsed,
    clockInClassification,
    employeeMembershipId,
    clockInAt,
    clockOutAt,
    reviewStatus,
    reviewedByMembershipId,
    reviewedAt,
    rejectionReason,
    minutesLate,
    workedMinutes,
    createdAt,
    updatedAt,
    shift,
    employee,
  ];
}

class AttendancePage {
  const AttendancePage({required this.data, required this.pagination});
  final List<AttendanceRecordApi> data;
  final ApiPagination pagination;
}

class AttendanceQuery {
  const AttendanceQuery({
    this.page = 1,
    this.limit = 20,
    this.from,
    this.to,
    this.employeeMembershipId,
    this.reviewStatus,
    this.shiftStatus,
  });
  final int page;
  final int limit;
  final DateTime? from;
  final DateTime? to;
  final String? employeeMembershipId;
  final AttendanceReviewStatus? reviewStatus;
  final ShiftStatus? shiftStatus;

  Map<String, Object?> toQuery({
    bool includeEmployee = true,
    bool includeShiftStatus = true,
  }) => {
    'page': page,
    'limit': limit,
    if (from != null) 'from': from!.toUtc().toIso8601String(),
    if (to != null) 'to': to!.toUtc().toIso8601String(),
    if (includeEmployee && employeeMembershipId != null)
      'employeeMembershipId': employeeMembershipId,
    if (reviewStatus != null && reviewStatus != AttendanceReviewStatus.unknown)
      'reviewStatus': switch (reviewStatus!) {
        AttendanceReviewStatus.pending => 'PENDING',
        AttendanceReviewStatus.approved => 'APPROVED',
        AttendanceReviewStatus.rejected => 'REJECTED',
        AttendanceReviewStatus.unknown => null,
      },
    if (includeShiftStatus && shiftStatus?.apiValue != null)
      'shiftStatus': shiftStatus!.apiValue,
  };

  AttendanceQuery copyWith({int? page}) => AttendanceQuery(
    page: page ?? this.page,
    limit: limit,
    from: from,
    to: to,
    employeeMembershipId: employeeMembershipId,
    reviewStatus: reviewStatus,
    shiftStatus: shiftStatus,
  );
}

abstract interface class AttendanceRepository {
  Future<AttendanceRecordApi> clockIn(String shiftId);
  Future<AttendanceRecordApi> clockOut(String shiftId);
  Future<AttendancePage> listWorkspaceAttendance(
    String workspaceId,
    AttendanceQuery query,
  );
  Future<AttendancePage> listAttendanceRequests(
    String workspaceId, {
    int page = 1,
    int limit = 20,
  });
  Future<AttendanceRecordApi> getWorkspaceAttendance(
    String workspaceId,
    String attendanceId,
  );
  Future<AttendanceRecordApi> reviewAttendance(
    String workspaceId,
    String attendanceId,
    AttendanceReviewDecision decision, {
    String? rejectionReason,
  });
  Future<AttendancePage> listMyAttendance(
    String workspaceId,
    AttendanceQuery query,
  );
}
