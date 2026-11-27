import 'package:equatable/equatable.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

class AttendanceDayDecision extends Equatable {
  const AttendanceDayDecision({
    required this.date,
    required this.employeeMembershipId,
    required this.status,
    required this.reason,
    required this.revision,
    required this.employee,
  });
  final String date, employeeMembershipId, status, reason;
  final int revision;
  final ShiftEmployeeSummary employee;
  factory AttendanceDayDecision.fromJson(Map<String, Object?> j) =>
      AttendanceDayDecision(
        date: ApiModelParser.string(j, 'operationalDate').split('T').first,
        employeeMembershipId: ApiModelParser.string(j, 'employeeMembershipId'),
        status: ApiModelParser.string(j, 'status'),
        reason: ApiModelParser.string(j, 'reason'),
        revision: ApiModelParser.integer(j, 'revision'),
        employee: ShiftEmployeeSummary.fromJson(
          ApiModelParser.map(j['employee']),
        ),
      );
  @override
  List<Object?> get props => [
    date,
    employeeMembershipId,
    status,
    reason,
    revision,
    employee,
  ];
}

class AttendanceControlEvent extends Equatable {
  const AttendanceControlEvent(
    this.date,
    this.action,
    this.actor,
    this.reason,
    this.before,
    this.after, {
    this.employee,
    this.operationalDate,
  });
  final DateTime date;
  final String action, actor, reason;
  final String? before, after, employee, operationalDate;
  factory AttendanceControlEvent.fromJson(Map<String, Object?> j) =>
      AttendanceControlEvent(
        ApiModelParser.date(j, 'createdAt'),
        ApiModelParser.string(j, 'action'),
        ApiModelParser.optionalString(j['actor']) ?? '',
        ApiModelParser.string(j, 'reason'),
        ApiModelParser.optionalMap(j['before'])?['status'] as String?,
        ApiModelParser.optionalMap(j['after'])?['status'] as String?,
        employee: ApiModelParser.optionalString(j['employee']),
        operationalDate: ApiModelParser.optionalString(j['operationalDate'])
            ?.split('T')
            .first,
      );
  @override
  List<Object?> get props => [
    date,
    action,
    actor,
    reason,
    before,
    after,
    employee,
    operationalDate,
  ];
}

class AttendanceApprovedDay extends Equatable {
  const AttendanceApprovedDay(
    this.date,
    this.employeeMembershipId,
    this.status,
    this.employee,
  );
  final String date, employeeMembershipId, status;
  final ShiftEmployeeSummary? employee;
  factory AttendanceApprovedDay.fromJson(Map<String, Object?> j) =>
      AttendanceApprovedDay(
        ApiModelParser.string(j, 'date'),
        ApiModelParser.string(j, 'employeeMembershipId'),
        ApiModelParser.string(j, 'status'),
        j['employee'] == null
            ? null
            : ShiftEmployeeSummary.fromJson(ApiModelParser.map(j['employee'])),
      );
  @override
  List<Object?> get props => [date, employeeMembershipId, status, employee];
}
