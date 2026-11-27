import 'package:shiftly/features/attendance/domain/entities/attendance_record_api_parser.dart';
import 'package:shiftly/features/attendance/domain/entities/attendance_record_meta.dart';
import 'package:shiftly/features/attendance/domain/entities/attendance_shift_summary.dart';
import 'package:shiftly/features/breaks/domain/shift_break_state.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/fixed_shift_models.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

class AttendanceRecordApi extends AttendanceRecordMeta {
  const AttendanceRecordApi({
    required this.id,
    required this.workspaceId,
    required this.shiftId,
    required this.employeeMembershipId,
    required this.clockInAt,
    required this.reviewStatus,
    required this.minutesLate,
    required this.createdAt,
    required this.updatedAt,
    required this.employee,
    super.dayStatus,
    super.dayDecisionReason,
    super.calculation,
    super.occurrenceKind,
    super.assignmentId,
    super.scheduleExceptionId,
    super.scheduleExceptionReason,
    super.extraAuthorizationId,
    super.enteredByMembershipId,
    super.clientAttendanceId,
    super.source = AttendanceSource.legacyShift,
    this.shift,
    this.clockOutAt,
    this.reviewedByMembershipId,
    this.reviewedAt,
    this.rejectionReason,
    this.workedMinutes,
    this.breakState,
    this.netWorkedMinutes,
    this.overtimeMinutes = 0,
    super.shiftTemplateId,
    super.templateName,
    super.workspaceTimezone,
    super.operationalDate,
    super.scheduledStartAt,
    super.scheduledEndAt,
    super.graceMinutesUsed,
    super.minimumWorkMinutesUsed,
    super.clockInClassification,
    super.clockInGeoStatus,
    super.clockInDistanceMeters,
    super.clockInLocationName,
    super.clockOutGeoStatus,
    super.clockOutDistanceMeters,
  });

  final String id, workspaceId, employeeMembershipId;
  final String? shiftId, reviewedByMembershipId, rejectionReason;
  final DateTime clockInAt, createdAt, updatedAt;
  final DateTime? clockOutAt, reviewedAt;
  final AttendanceReviewStatus reviewStatus;
  final int minutesLate, overtimeMinutes;
  final int? workedMinutes, netWorkedMinutes;
  final ShiftBreakState? breakState;
  final AttendanceShiftSummary? shift;
  final ShiftEmployeeSummary employee;

  bool get isOpen =>
      clockOutAt == null && reviewStatus != AttendanceReviewStatus.rejected;
  bool get canReview =>
      reviewStatus == AttendanceReviewStatus.pending &&
      source != AttendanceSource.unknown;

  factory AttendanceRecordApi.fromJson(Map<String, Object?> json) =>
      parseAttendanceRecordApi(json);

  @override
  List<Object?> get props => [
    ...super.props,
    id,
    workspaceId,
    shiftId,
    employeeMembershipId,
    clockInAt,
    clockOutAt,
    reviewStatus,
    reviewedByMembershipId,
    reviewedAt,
    rejectionReason,
    minutesLate,
    workedMinutes,
    breakState,
    netWorkedMinutes,
    overtimeMinutes,
    createdAt,
    updatedAt,
    shift,
    employee,
  ];
}
