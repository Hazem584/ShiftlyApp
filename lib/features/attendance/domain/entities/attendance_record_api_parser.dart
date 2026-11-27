import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/attendance/domain/entities/attendance_record_api.dart';
import 'package:shiftly/features/attendance/domain/entities/attendance_shift_summary.dart';
import 'package:shiftly/features/breaks/domain/shift_break_state.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/fixed_shift_models.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

AttendanceRecordApi parseAttendanceRecordApi(
  Map<String, Object?> json,
) => AttendanceRecordApi(
  dayStatus: ApiModelParser.optionalString(json['dayStatus']),
  dayDecisionReason: ApiModelParser.optionalString(json['dayDecisionReason']),
  calculation: ApiModelParser.optionalMap(json['calculation']),
  occurrenceKind: ApiModelParser.optionalString(json['occurrenceKind']),
  assignmentId: ApiModelParser.optionalString(json['assignmentId']),
  scheduleExceptionId: ApiModelParser.optionalString(
    json['scheduleExceptionId'],
  ),
  scheduleExceptionReason: ApiModelParser.optionalString(
    ApiModelParser.optionalMap(json['scheduleException'])?['reason'],
  ),
  extraAuthorizationId: ApiModelParser.optionalString(
    json['extraAuthorizationId'],
  ),
  enteredByMembershipId: ApiModelParser.optionalString(
    json['enteredByMembershipId'],
  ),
  clientAttendanceId: ApiModelParser.optionalString(json['clientAttendanceId']),
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
  clockInGeoStatus: ApiModelParser.optionalString(json['clockInGeoStatus']),
  clockInDistanceMeters: ApiModelParser.optionalInteger(
    json['clockInDistanceMeters'],
  ),
  clockInLocationName: ApiModelParser.optionalString(
    ApiModelParser.optionalMap(json['clockInLocation'])?['name'],
  ),
  clockOutGeoStatus: ApiModelParser.optionalString(json['clockOutGeoStatus']),
  clockOutDistanceMeters: ApiModelParser.optionalInteger(
    json['clockOutDistanceMeters'],
  ),
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
  netWorkedMinutes: ApiModelParser.optionalInteger(json['netWorkedMinutes']),
  overtimeMinutes: ApiModelParser.optionalInteger(json['overtimeMinutes']) ?? 0,
  breakState: json['breakState'] == null
      ? null
      : ShiftBreakState.fromJson(ApiModelParser.map(json['breakState'])),
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
