part of '../../notification_repository.dart';

enum NotificationType {
  attendanceClockedIn,
  attendanceClockedOut,
  leaveRequestCreated,
  leaveRequestApproved,
  leaveRequestRejected,
  shiftAssigned,
  shiftUpdated,
  shiftCancelled,
  unknown;

  static NotificationType parse(Object? value) => switch (value) {
    'ATTENDANCE_CLOCKED_IN' => attendanceClockedIn,
    'ATTENDANCE_CLOCKED_OUT' => attendanceClockedOut,
    'LEAVE_REQUEST_CREATED' => leaveRequestCreated,
    'LEAVE_REQUEST_APPROVED' => leaveRequestApproved,
    'LEAVE_REQUEST_REJECTED' => leaveRequestRejected,
    'SHIFT_ASSIGNED' => shiftAssigned,
    'SHIFT_UPDATED' => shiftUpdated,
    'SHIFT_CANCELLED' => shiftCancelled,
    _ => unknown,
  };

  String? get apiValue => switch (this) {
    attendanceClockedIn => 'ATTENDANCE_CLOCKED_IN',
    attendanceClockedOut => 'ATTENDANCE_CLOCKED_OUT',
    leaveRequestCreated => 'LEAVE_REQUEST_CREATED',
    leaveRequestApproved => 'LEAVE_REQUEST_APPROVED',
    leaveRequestRejected => 'LEAVE_REQUEST_REJECTED',
    shiftAssigned => 'SHIFT_ASSIGNED',
    shiftUpdated => 'SHIFT_UPDATED',
    shiftCancelled => 'SHIFT_CANCELLED',
    unknown => null,
  };
}
