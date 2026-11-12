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

class AttendanceMonthControl extends Equatable {
  const AttendanceMonthControl({
    this.revision = 0,
    this.closedAt,
    this.overrides = const [],
    this.approvedDays = const [],
    this.events = const [],
    this.pending = 0,
    this.open = 0,
    this.pendingCorrections = 0,
    this.unfinishedShifts = 0,
    this.workMinutes = 0,
    this.overtimeMinutes = 0,
    this.present = 0,
    this.absent = 0,
    this.late = 0,
    this.leave = 0,
  });
  final int revision,
      pending,
      open,
      pendingCorrections,
      unfinishedShifts,
      workMinutes,
      overtimeMinutes,
      present,
      absent,
      late,
      leave;
  final DateTime? closedAt;
  final List<AttendanceApprovedDay> approvedDays;
  final List<AttendanceDayDecision> overrides;
  final List<AttendanceControlEvent> events;
  bool get closed => closedAt != null;
  factory AttendanceMonthControl.fromJson(Map<String, Object?> j) {
    final summary = ApiModelParser.map(j['summary']);
    final days = ApiModelParser.list(
      summary['days'],
      'days',
    ).map((e) => ApiModelParser.map(e)).toList();
    int count(String status) => days.where((d) => d['status'] == status).length;
    int total(String field) =>
        days.fold(0, (s, d) => s + ApiModelParser.integer(d, field));
    return AttendanceMonthControl(
      approvedDays: j['closedAt'] == null
          ? const []
          : days.map(AttendanceApprovedDay.fromJson).toList(),
      revision: ApiModelParser.integer(j, 'revision'),
      closedAt: ApiModelParser.optionalDate(j['closedAt']),
      overrides: ApiModelParser.list(j['overrides'], 'overrides')
          .map((v) => AttendanceDayDecision.fromJson(ApiModelParser.map(v)))
          .toList(),
      events: ApiModelParser.list(j['events'], 'events')
          .map((v) => AttendanceControlEvent.fromJson(ApiModelParser.map(v)))
          .toList(),
      pending: ApiModelParser.integer(summary, 'pending'),
      open: ApiModelParser.integer(summary, 'open'),
      pendingCorrections: ApiModelParser.integer(summary, 'pendingCorrections'),
      unfinishedShifts:
          ApiModelParser.optionalInteger(summary['unfinishedShifts']) ?? 0,
      workMinutes: total('workMinutes'),
      overtimeMinutes: total('overtimeMinutes'),
      present: count('PRESENT'),
      absent: count('ABSENT'),
      late: count('LATE'),
      leave: count('LEAVE'),
    );
  }
  @override
  List<Object?> get props => [
    revision,
    closedAt,
    overrides,
    approvedDays,
    events,
    pending,
    open,
    pendingCorrections,
    unfinishedShifts,
    workMinutes,
    overtimeMinutes,
    present,
    absent,
    late,
    leave,
  ];
}
