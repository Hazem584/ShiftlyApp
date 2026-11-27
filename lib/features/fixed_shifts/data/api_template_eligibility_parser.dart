import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/schedule_exception.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';

TemplateEligibility parseTemplateEligibility(Object? data) {
  final json = ApiModelParser.map(data);
  final recommendedJson = ApiModelParser.optionalMap(
    json['recommended'],
    'recommended',
  );
  return TemplateEligibility(
    dayExceptions:
        (json['dayExceptions'] == null
                ? <Object?>[]
                : ApiModelParser.list(json['dayExceptions']))
            .map((e) => ScheduleExceptionNotice.fromJson(ApiModelParser.map(e)))
            .toList(),
    status: ApiModelParser.optionalString(json['status']) ?? 'UNKNOWN',
    geofenceMode: ApiModelParser.optionalString(json['geofenceMode']) ?? 'OFF',
    openAttendanceId: json['openAttendance'] == null
        ? null
        : ApiModelParser.string(
            ApiModelParser.map(json['openAttendance']),
            'id',
          ),
    authorizedOccurrences:
        (json['authorizedOccurrences'] == null
                ? <Object?>[]
                : ApiModelParser.list(
                    json['authorizedOccurrences'],
                    'authorizedOccurrences',
                  ))
            .map((v) => EligibleShiftOccurrence.fromJson(ApiModelParser.map(v)))
            .toList(),
    workspaceId: ApiModelParser.string(json, 'workspaceId'),
    timezone: ApiModelParser.string(json, 'timezone'),
    evaluatedAt: ApiModelParser.date(json, 'evaluatedAt'),
    recommended: recommendedJson == null
        ? null
        : EligibleShiftOccurrence.fromJson(recommendedJson),
    eligibleTemplates:
        ApiModelParser.list(json['eligibleTemplates'], 'eligibleTemplates')
            .map(
              (value) =>
                  EligibleShiftOccurrence.fromJson(ApiModelParser.map(value)),
            )
            .toList(growable: false),
  );
}
