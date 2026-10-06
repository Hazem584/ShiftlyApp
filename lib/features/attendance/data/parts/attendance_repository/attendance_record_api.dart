part of '../../attendance_repository.dart';

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
