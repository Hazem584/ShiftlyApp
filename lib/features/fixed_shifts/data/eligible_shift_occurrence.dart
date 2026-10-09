import 'package:equatable/equatable.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/network/api_model_parser.dart';

import 'fixed_shift_dates.dart';
import 'fixed_shift_repository.dart';

class EligibleShiftOccurrence extends Equatable {
  const EligibleShiftOccurrence({
    this.occurrenceKind,
    this.assignmentId,
    this.extraAuthorizationId,
    this.timezone,
    this.conversionPolicy,
    this.eligible = false,
    this.alreadyUsed = false,
    required this.template,
    required this.operationalDate,
    required this.scheduledStartAt,
    required this.scheduledEndAt,
    required this.checkInWindowStart,
    required this.checkInWindowEnd,
    required this.classification,
    required this.lateMinutes,
    required this.recommended,
  });

  final String? occurrenceKind,
      assignmentId,
      extraAuthorizationId,
      timezone,
      conversionPolicy;
  final bool eligible, alreadyUsed;
  String get identity =>
      '$occurrenceKind|${template.id}|$assignmentId|$extraAuthorizationId|$operationalDate';
  final ShiftTemplate template;
  final String operationalDate;
  final DateTime scheduledStartAt;
  final DateTime scheduledEndAt;
  final DateTime checkInWindowStart;
  final DateTime checkInWindowEnd;
  final AttendanceClassification classification;
  final int lateMinutes;
  final bool recommended;

  bool get canClockIn =>
      scheduledEndAt.isAfter(scheduledStartAt) &&
      !checkInWindowEnd.isBefore(checkInWindowStart) &&
      timezone != null &&
      WorkspaceTime.isValid(timezone!) &&
      template.active &&
      classification.isActionable &&
      eligible &&
      !alreadyUsed &&
      (conversionPolicy == 'POSTGRES_V1' ||
          conversionPolicy == null ||
          conversionPolicy == 'LEGACY_UNVERSIONED') &&
      ((occurrenceKind == 'BASELINE' &&
              assignmentId != null &&
              extraAuthorizationId == null) ||
          (occurrenceKind == 'EXTRA' &&
              extraAuthorizationId != null &&
              assignmentId == null));

  factory EligibleShiftOccurrence.fromJson(Map<String, Object?> json) {
    final recommended = json['recommended'];
    if (recommended is! bool) {
      throw const FormatException('Invalid recommended');
    }
    final schedule = ApiModelParser.map(json['template']);
    return EligibleShiftOccurrence(
      occurrenceKind: ApiModelParser.optionalString(json['occurrenceKind']),
      assignmentId: ApiModelParser.optionalString(json['assignmentId']),
      extraAuthorizationId: ApiModelParser.optionalString(
        json['extraAuthorizationId'],
      ),
      timezone: ApiModelParser.optionalString(schedule['timezone']),
      conversionPolicy: ApiModelParser.optionalString(
        schedule['conversionPolicy'],
      ),
      eligible: json['eligible'] == true,
      alreadyUsed: json['alreadyUsed'] != false,
      template: ShiftTemplate.fromJson(
        ApiModelParser.map(json['template'], 'template'),
      ),
      operationalDate: fixedShiftDateOnly(json, 'operationalDate'),
      scheduledStartAt: ApiModelParser.date(json, 'scheduledStartAt'),
      scheduledEndAt: ApiModelParser.date(json, 'scheduledEndAt'),
      checkInWindowStart: ApiModelParser.date(json, 'checkInWindowStart'),
      checkInWindowEnd: ApiModelParser.date(json, 'checkInWindowEnd'),
      classification: AttendanceClassification.parse(
        json['expectedClockInClassification'],
      ),
      lateMinutes: ApiModelParser.integer(json, 'lateMinutes'),
      recommended: recommended,
    );
  }

  @override
  List<Object?> get props => [
    occurrenceKind,
    assignmentId,
    extraAuthorizationId,
    timezone,
    conversionPolicy,
    eligible,
    alreadyUsed,
    template,
    operationalDate,
    scheduledStartAt,
    scheduledEndAt,
    checkInWindowStart,
    checkInWindowEnd,
    classification,
    lateMinutes,
    recommended,
  ];
}
