import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/features/attendance/data/leave_request_repository.dart';

part 'parts/leave_request_display/leave_status_badge.dart';
part 'parts/leave_request_display/leave_detail_row.dart';

String leaveTypeLabel(LeaveRequestType type) => switch (type) {
  LeaveRequestType.annualLeave => 'Annual leave',
  LeaveRequestType.sickLeave => 'Sick leave',
  LeaveRequestType.emergencyLeave => 'Emergency leave',
  LeaveRequestType.earlyLeave => 'Early departure',
  LeaveRequestType.other => 'Other leave',
  LeaveRequestType.unknown => 'Unknown leave type',
};
