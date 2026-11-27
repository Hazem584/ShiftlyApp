import 'package:equatable/equatable.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/fixed_shift_models.dart';

abstract class AttendanceRecordMeta extends Equatable {
  const AttendanceRecordMeta({
    this.dayStatus,
    this.dayDecisionReason,
    this.calculation,
    this.occurrenceKind,
    this.assignmentId,
    this.scheduleExceptionId,
    this.scheduleExceptionReason,
    this.extraAuthorizationId,
    this.enteredByMembershipId,
    this.clientAttendanceId,
    this.source = AttendanceSource.legacyShift,
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

  final String? dayStatus,
      dayDecisionReason,
      occurrenceKind,
      scheduleExceptionId,
      scheduleExceptionReason,
      assignmentId,
      extraAuthorizationId,
      enteredByMembershipId,
      clientAttendanceId,
      shiftTemplateId,
      templateName,
      workspaceTimezone,
      operationalDate;
  final Map<String, Object?>? calculation;
  final AttendanceSource source;
  final DateTime? scheduledStartAt, scheduledEndAt;
  final int? graceMinutesUsed, minimumWorkMinutesUsed;
  final AttendanceClassification? clockInClassification;

  @override
  List<Object?> get props => [
    dayStatus, dayDecisionReason, calculation, occurrenceKind, assignmentId,
    scheduleExceptionId, scheduleExceptionReason, extraAuthorizationId,
    enteredByMembershipId, clientAttendanceId, source, shiftTemplateId,
    templateName, workspaceTimezone, operationalDate, scheduledStartAt,
    scheduledEndAt, graceMinutesUsed, minimumWorkMinutesUsed,
    clockInClassification,
  ];
}
