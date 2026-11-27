import 'package:equatable/equatable.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/attendance/domain/entities/attendance_control_models.dart';

export 'attendance_control_models.dart';

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
    revision, closedAt, overrides, approvedDays, events, pending, open,
    pendingCorrections, unfinishedShifts, workMinutes, overtimeMinutes,
    present, absent, late, leave,
  ];
}
