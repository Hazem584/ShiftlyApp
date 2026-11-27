import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/services/fixed_shift_dates.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

Map<String, ShiftRecord> collectValidCalendarShifts(
  List<ShiftRecord> shifts,
  String workspaceId,
) {
  final validShifts = <String, ShiftRecord>{};
  for (final shift in shifts) {
    if (shift.workspaceId == workspaceId &&
        (shift.status == ShiftStatus.scheduled ||
            shift.status == ShiftStatus.completed)) {
      validShifts.putIfAbsent(shift.id, () => shift);
    }
  }
  return validShifts;
}

({
  Map<String, AttendanceRecordApi> attendance,
  Map<String, String> templateDays,
})
collectValidCalendarAttendance(
  List<AttendanceRecordApi> attendance,
  String workspaceId,
) {
  final validAttendance = <String, AttendanceRecordApi>{};
  final templateDays = <String, String>{};
  for (final record in attendance) {
    if (record.workspaceId != workspaceId ||
        validAttendance.containsKey(record.id) ||
        record.reviewStatus == AttendanceReviewStatus.rejected ||
        record.reviewStatus == AttendanceReviewStatus.unknown) {
      continue;
    }
    switch (record.source) {
      case AttendanceSource.legacyShift:
        if (record.shift == null ||
            record.shift!.status == ShiftStatus.cancelled ||
            record.shift!.status == ShiftStatus.unknown) {
          continue;
        }
      case AttendanceSource.template:
        if (record.operationalDate == null ||
            record.clockInClassification == AttendanceClassification.unknown) {
          continue;
        }
        try {
          fixedShiftDateOnly({
            'date': record.operationalDate!.split('T').first,
          }, 'date');
          final date = fixedShiftOperationalDate({
            'date': record.operationalDate,
          }, 'date');
          templateDays.putIfAbsent(record.id, () => date);
        } on FormatException {
          continue;
        }
      case AttendanceSource.unknown:
        continue;
    }
    validAttendance.putIfAbsent(record.id, () => record);
  }
  return (attendance: validAttendance, templateDays: templateDays);
}

Map<String, LeaveRequestRecord> collectApprovedCalendarLeave(
  List<LeaveRequestRecord> leaveRequests,
  String workspaceId,
) {
  final approvedLeave = <String, LeaveRequestRecord>{};
  for (final request in leaveRequests) {
    if (request.workspaceId == workspaceId &&
        request.status == LeaveRequestStatus.approved) {
      approvedLeave.putIfAbsent(request.id, () => request);
    }
  }
  return approvedLeave;
}
