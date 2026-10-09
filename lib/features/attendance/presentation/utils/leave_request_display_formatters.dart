import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';

String leaveTypeLabel(LeaveRequestType type) => switch (type) {
  LeaveRequestType.annualLeave => 'Annual leave',
  LeaveRequestType.sickLeave => 'Sick leave',
  LeaveRequestType.emergencyLeave => 'Emergency leave',
  LeaveRequestType.earlyLeave => 'Early departure',
  LeaveRequestType.other => 'Other leave',
  LeaveRequestType.unknown => 'Unknown leave type',
};
