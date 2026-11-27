import 'package:equatable/equatable.dart';
import 'package:shiftly/features/shifts/domain/entities/attendance_review_status.dart';
import 'package:shiftly/features/shifts/domain/entities/shift_attendance_summary.dart';
import 'package:shiftly/features/shifts/domain/entities/shift_employee_summary.dart';
import 'package:shiftly/features/shifts/domain/entities/shift_record_parser.dart';
import 'package:shiftly/features/shifts/domain/entities/shift_status.dart';

class ShiftRecord extends Equatable {
  const ShiftRecord({
    required this.id,
    required this.workspaceId,
    required this.employeeMembershipId,
    required this.createdByMembershipId,
    required this.startsAt,
    required this.endsAt,
    required this.breakMinutes,
    required this.graceMinutes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.employee,
    this.notes,
    this.assignmentId,
    this.extraAuthorizationId,
    this.attendance,
  });

  final String id, workspaceId, employeeMembershipId, createdByMembershipId;
  final DateTime startsAt, endsAt, createdAt, updatedAt;
  final int breakMinutes, graceMinutes;
  final String? notes, assignmentId, extraAuthorizationId;
  final ShiftStatus status;
  final ShiftEmployeeSummary employee;
  final ShiftAttendanceSummary? attendance;

  bool get canManage => status == ShiftStatus.scheduled;
  bool get canClockIn => status == ShiftStatus.scheduled && attendance == null;
  bool get canClockOut =>
      status == ShiftStatus.scheduled &&
      attendance != null &&
      attendance!.clockOutAt == null &&
      attendance!.reviewStatus != AttendanceReviewStatus.rejected &&
      attendance!.reviewStatus != AttendanceReviewStatus.unknown;

  ShiftRecord copyWith({
    ShiftStatus? status,
    ShiftAttendanceSummary? attendance,
  }) => ShiftRecord(
    id: id,
    workspaceId: workspaceId,
    employeeMembershipId: employeeMembershipId,
    createdByMembershipId: createdByMembershipId,
    startsAt: startsAt,
    endsAt: endsAt,
    breakMinutes: breakMinutes,
    graceMinutes: graceMinutes,
    notes: notes,
    assignmentId: assignmentId,
    extraAuthorizationId: extraAuthorizationId,
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: updatedAt,
    employee: employee,
    attendance: attendance ?? this.attendance,
  );

  factory ShiftRecord.fromJson(Map<String, Object?> json) =>
      parseShiftRecordJson(json);

  @override
  List<Object?> get props => [
    id,
    workspaceId,
    employeeMembershipId,
    createdByMembershipId,
    startsAt,
    endsAt,
    breakMinutes,
    graceMinutes,
    notes,
    assignmentId,
    extraAuthorizationId,
    status,
    createdAt,
    updatedAt,
    employee,
    attendance,
  ];
}
