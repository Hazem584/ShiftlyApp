import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/shifts/domain/entities/shift_attendance_summary.dart';
import 'package:shiftly/features/shifts/domain/entities/shift_employee_summary.dart';
import 'package:shiftly/features/shifts/domain/entities/shift_record.dart';
import 'package:shiftly/features/shifts/domain/entities/shift_status.dart';

ShiftRecord parseShiftRecordJson(Map<String, Object?> json) {
  final employee = ApiModelParser.map(json['employee'], 'employee');
  final attendance = ApiModelParser.optionalMap(
    json['attendance'],
    'attendance',
  );
  return ShiftRecord(
    id: ApiModelParser.string(json, 'id'),
    workspaceId: ApiModelParser.string(json, 'workspaceId'),
    employeeMembershipId: ApiModelParser.string(json, 'employeeMembershipId'),
    createdByMembershipId: ApiModelParser.string(json, 'createdByMembershipId'),
    startsAt: ApiModelParser.date(json, 'startsAt'),
    endsAt: ApiModelParser.date(json, 'endsAt'),
    breakMinutes: ApiModelParser.integer(json, 'breakMinutes'),
    graceMinutes: ApiModelParser.integer(json, 'graceMinutes'),
    notes: ApiModelParser.optionalString(json['notes']),
    assignmentId: ApiModelParser.optionalString(json['assignmentId']),
    extraAuthorizationId: ApiModelParser.optionalString(
      json['extraAuthorizationId'],
    ),
    status: ShiftStatus.parse(json['status']),
    createdAt: ApiModelParser.date(json, 'createdAt'),
    updatedAt: ApiModelParser.date(json, 'updatedAt'),
    employee: ShiftEmployeeSummary.fromJson(employee),
    attendance: attendance == null
        ? null
        : ShiftAttendanceSummary.fromJson(attendance),
  );
}
