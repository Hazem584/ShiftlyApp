import 'package:equatable/equatable.dart';
import 'package:shiftly/features/breaks/domain/shift_break_state.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/fixed_shift_models.dart';

import 'flexible_attendance_parser.dart';
import 'flexible_attendance_values.dart';

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
    this.breakState,
    this.netWorkedMinutes,
    this.overtimeMinutes = 0,
  });

  final String? occurrenceKind,
      assignmentId,
      extraAuthorizationId,
      enteredByMembershipId,
      reviewStatus;
  final String id, workspaceId, employeeMembershipId;
  final AttendanceSource source;
  final String? shiftId,
      shiftTemplateId,
      clientAttendanceId,
      templateName,
      templateColor,
      workspaceTimezone,
      operationalDate;
  final DateTime? scheduledStartAt, scheduledEndAt;
  final int? graceMinutesUsed, minimumWorkMinutesUsed;
  final AttendanceClassification? classification;
  final DateTime clockInAt;
  final DateTime? clockOutAt;
  final int minutesLate;
  final int? workedMinutes, netWorkedMinutes;
  final int overtimeMinutes;
  final ShiftBreakState? breakState;
  final DateTime createdAt, updatedAt;

  bool get isOpen => clockOutAt == null && reviewStatus != 'REJECTED';
  bool get isTemplate => source == AttendanceSource.template;
  bool get isActionable =>
      isTemplate &&
      classification != null &&
      classification != AttendanceClassification.unknown;

  factory FlexibleAttendance.fromJson(Map<String, Object?> json) =>
      parseFlexibleAttendance(json);

  @override
  List<Object?> get props => flexibleAttendanceValues(this);
}
