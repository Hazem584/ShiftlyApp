import 'package:equatable/equatable.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/fixed_shift_models.dart';
import 'package:shiftly/features/fixed_shifts/domain/services/fixed_shift_dates.dart';

class FlexibleAttendance extends Equatable {
  const FlexibleAttendance({
    required this.id,
    required this.workspaceId,
    required this.employeeMembershipId,
    required this.source,
    required this.clockInAt,
    required this.minutesLate,
    required this.createdAt,
    required this.updatedAt,
    this.occurrenceKind,
    this.assignmentId,
    this.extraAuthorizationId,
    this.enteredByMembershipId,
    this.reviewStatus,
    this.shiftId,
    this.shiftTemplateId,
    this.clientAttendanceId,
    this.templateName,
    this.templateColor,
    this.workspaceTimezone,
    this.operationalDate,
    this.scheduledStartAt,
    this.scheduledEndAt,
    this.graceMinutesUsed,
    this.minimumWorkMinutesUsed,
    this.classification,
    this.clockOutAt,
    this.workedMinutes,
  });

  final String? occurrenceKind,
      assignmentId,
      extraAuthorizationId,
      enteredByMembershipId,
      reviewStatus;
  final String id;
  final String workspaceId;
  final String employeeMembershipId;
  final AttendanceSource source;
  final String? shiftId;
  final String? shiftTemplateId;
  final String? clientAttendanceId;
  final String? templateName;
  final String? templateColor;
  final String? workspaceTimezone;
  final String? operationalDate;
  final DateTime? scheduledStartAt;
  final DateTime? scheduledEndAt;
  final int? graceMinutesUsed;
  final int? minimumWorkMinutesUsed;
  final AttendanceClassification? classification;
  final DateTime clockInAt;
  final DateTime? clockOutAt;
  final int minutesLate;
  final int? workedMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOpen => clockOutAt == null && reviewStatus != 'REJECTED';
  bool get isTemplate => source == AttendanceSource.template;
  bool get isActionable =>
      isTemplate &&
      classification != null &&
      classification != AttendanceClassification.unknown;

  factory FlexibleAttendance.fromJson(Map<String, Object?> json) {
    final template = ApiModelParser.optionalMap(
      json['shiftTemplate'],
      'shiftTemplate',
    );
    final source = AttendanceSource.parse(json['source']);
    final classification = json['clockInClassification'] == null
        ? null
        : AttendanceClassification.parse(json['clockInClassification']);
    final value = FlexibleAttendance(
      occurrenceKind: ApiModelParser.optionalString(json['occurrenceKind']),
      assignmentId: ApiModelParser.optionalString(json['assignmentId']),
      extraAuthorizationId: ApiModelParser.optionalString(
        json['extraAuthorizationId'],
      ),
      enteredByMembershipId: ApiModelParser.optionalString(
        json['enteredByMembershipId'],
      ),
      reviewStatus: ApiModelParser.optionalString(json['reviewStatus']),
      id: ApiModelParser.string(json, 'id'),
      workspaceId: ApiModelParser.string(json, 'workspaceId'),
      employeeMembershipId: ApiModelParser.string(json, 'employeeMembershipId'),
      source: source,
      shiftId: ApiModelParser.optionalString(json['shiftId']),
      shiftTemplateId: ApiModelParser.optionalString(json['shiftTemplateId']),
      clientAttendanceId: ApiModelParser.optionalString(
        json['clientAttendanceId'],
      ),
      templateName: ApiModelParser.optionalString(json['templateName']),
      templateColor: template == null
          ? null
          : ApiModelParser.optionalString(template['color']),
      workspaceTimezone: ApiModelParser.optionalString(
        json['workspaceTimezone'],
      ),
      operationalDate: json['operationalDate'] == null
          ? null
          : fixedShiftOperationalDate(json, 'operationalDate'),
      scheduledStartAt: ApiModelParser.optionalDate(json['scheduledStartAt']),
      scheduledEndAt: ApiModelParser.optionalDate(json['scheduledEndAt']),
      graceMinutesUsed: ApiModelParser.optionalInteger(
        json['graceMinutesUsed'],
      ),
      minimumWorkMinutesUsed: ApiModelParser.optionalInteger(
        json['minimumWorkMinutesUsed'],
      ),
      classification: classification,
      clockInAt: ApiModelParser.date(json, 'clockInAt'),
      clockOutAt: ApiModelParser.optionalDate(json['clockOutAt']),
      minutesLate: ApiModelParser.integer(json, 'minutesLate'),
      workedMinutes: ApiModelParser.optionalInteger(json['workedMinutes']),
      createdAt: ApiModelParser.date(json, 'createdAt'),
      updatedAt: ApiModelParser.date(json, 'updatedAt'),
    );
    if (value.minutesLate < 0 ||
        (value.graceMinutesUsed != null && value.graceMinutesUsed! < 0) ||
        (value.minimumWorkMinutesUsed != null &&
            value.minimumWorkMinutesUsed! < 0) ||
        (value.workedMinutes != null && value.workedMinutes! < 0)) {
      throw const FormatException('Invalid attendance minute value');
    }
    if (source == AttendanceSource.template &&
        (value.shiftTemplateId == null ||
            value.templateName == null ||
            value.workspaceTimezone == null ||
            value.operationalDate == null ||
            value.scheduledStartAt == null ||
            value.scheduledEndAt == null ||
            value.classification == null)) {
      throw const FormatException('Incomplete template attendance');
    }
    if (source == AttendanceSource.legacyShift && value.shiftId == null) {
      throw const FormatException('Incomplete legacy attendance');
    }
    return value;
  }

  @override
  List<Object?> get props => [
    occurrenceKind,
    assignmentId,
    extraAuthorizationId,
    enteredByMembershipId,
    reviewStatus,
    id,
    workspaceId,
    employeeMembershipId,
    source,
    shiftId,
    shiftTemplateId,
    clientAttendanceId,
    templateName,
    templateColor,
    workspaceTimezone,
    operationalDate,
    scheduledStartAt,
    scheduledEndAt,
    graceMinutesUsed,
    minimumWorkMinutesUsed,
    classification,
    clockInAt,
    clockOutAt,
    minutesLate,
    workedMinutes,
    createdAt,
    updatedAt,
  ];
}
