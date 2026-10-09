import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';

String employeeDashboardScreenLeaveType(LeaveRequestType type) =>
    switch (type) {
      LeaveRequestType.annualLeave => 'Annual leave',
      LeaveRequestType.sickLeave => 'Sick leave',
      LeaveRequestType.emergencyLeave => 'Emergency leave',
      LeaveRequestType.earlyLeave => 'Early leave',
      LeaveRequestType.other => 'Other leave',
      LeaveRequestType.unknown => 'Leave request',
    };

String employeeDashboardScreenLeaveStatus(LeaveRequestStatus status) =>
    switch (status) {
      LeaveRequestStatus.pending => 'Pending',
      LeaveRequestStatus.approved => 'Approved',
      LeaveRequestStatus.rejected => 'Rejected',
      LeaveRequestStatus.cancelled => 'Cancelled',
      LeaveRequestStatus.unknown => 'Updated',
    };
