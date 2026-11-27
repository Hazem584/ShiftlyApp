String? apiErrorAttendanceMessage(String? code) => switch (code) {
  'SHIFT_EMPLOYEE_INVALID' => 'Choose an active employee from this workspace.',
  'SHIFT_EMPLOYEE_NOT_ACTIVE' => 'The selected employee is not active.',
  'SHIFT_OVERLAP' => 'This employee already has an overlapping shift.',
  'SHIFT_INVALID_TIME_RANGE' =>
    'Shift end must be after its start and the break must be shorter.',
  'SHIFT_TOO_LONG' => 'A shift cannot be longer than 24 hours.',
  'SHIFT_CANCELLED' => 'This shift has been cancelled.',
  'SHIFT_ALREADY_COMPLETED' => 'This shift is already completed.',
  'SHIFT_NOT_FOUND' => 'That shift could not be found.',
  'CLOCK_IN_TOO_EARLY' => 'Clock-in is not available yet for this shift.',
  'CLOCK_IN_TOO_LATE' => 'This shift has already ended.',
  'ATTENDANCE_ALREADY_EXISTS' => 'You have already clocked in for this shift.',
  'ATTENDANCE_ALREADY_CLOCKED_OUT' =>
    'You have already clocked out for this shift.',
  'ATTENDANCE_REJECTED' => 'Rejected attendance cannot be clocked out.',
  'ATTENDANCE_ALREADY_REVIEWED' =>
    'This attendance request has already been reviewed.',
  'ATTENDANCE_NOT_FOUND' => 'That attendance record could not be found.',
  'LEAVE_EMPLOYEE_NOT_ACTIVE' =>
    'Only active employees can manage leave requests.',
  'LEAVE_REQUEST_INVALID_TIME_RANGE' => 'Leave end must be after its start.',
  'LEAVE_REQUEST_TOO_LONG' => 'A leave request cannot be longer than 365 days.',
  'LEAVE_REQUEST_OVERLAP' =>
    'This leave overlaps another pending or approved request.',
  'LEAVE_REQUEST_NOT_FOUND' => 'That leave request could not be found.',
  'LEAVE_REQUEST_ALREADY_REVIEWED' =>
    'This leave request has already been reviewed.',
  'LEAVE_REQUEST_ALREADY_CANCELLED' =>
    'This leave request has already been cancelled.',
  'LEAVE_REQUEST_NOT_PENDING' => 'Only pending leave requests can be changed.',
  'CORRECTION_PENDING' =>
    'This attendance already has a request waiting for review.',
  'CORRECTION_STALE' => 'Attendance changed after this request. Decline it and ask for a new request.',
  'CORRECTION_TIME_INVALID' =>
    'Choose a completed period of up to 24 hours, ending before now.',
  'ATTENDANCE_MONTH_CLOSED' =>
    'Reopen the approved month with a reason before editing attendance.',
  'ATTENDANCE_MONTH_NOT_ENDED' => 'Only a completed month can be approved.',
  'ATTENDANCE_MONTH_REVIEW_PENDING' =>
    'Review open attendance and pending requests before closing the month.',
  'ATTENDANCE_CONTROL_CONFLICT' =>
    'Attendance changed. Refresh the calendar and retry.',
  'ATTENDANCE_DAY_INVALID' =>
    'Choose a valid attendance date that is not in the future.',
  'ATTENDANCE_DAY_OPEN' =>
    'Complete the open attendance before changing its day status.',
  'ATTENDANCE_DAY_RECORD_REQUIRED' => 'Record or correct the attendance times before marking this day present or late.',
  'ATTENDANCE_ALREADY_OPEN' =>
    'You already have an open attendance. Refresh to view it.',
  'ATTENDANCE_OVERLAP' =>
    'This attendance would overlap another attendance record.',
  'ATTENDANCE_IDEMPOTENCY_CONFLICT' =>
    'This clock-in retry no longer matches the original request.',
  'ATTENDANCE_CONCURRENT_CONFLICT' =>
    'Attendance changed at the same time. Refresh and retry.',
  'OUTSIDE_WORK_LOCATION' => 'You are outside the allowed workplace area. Move closer to your work location and try again.',
  'LOCATION_REQUIRED' || 'LOCATION_SERVICES_DISABLED' =>
    'Turn on location services to record attendance at this workspace.',
  'LOCATION_PERMISSION_DENIED' =>
    'Allow location permission to record attendance at your workplace.',
  'LOCATION_ACCURACY_TOO_LOW' =>
    'GPS signal is too weak. Move near a window or outdoors and retry.',
  'MOCK_LOCATION_DETECTED' =>
    'Disable mock location apps before recording attendance.',
  'WORK_LOCATION_NAME_CONFLICT' =>
    'An active work location already uses this name.',
  'WORK_LOCATION_NOT_FOUND' => 'That work location could not be found.',
  'WORK_LOCATION_REQUIRED_FOR_ENFORCE' =>
    'Add at least one active work location before enforcing geofence.',
  'SELFIE_REQUIRED' =>
    'Take a front-camera selfie to clock in at this workspace.',
  'SELFIE_CAMERA_UNAVAILABLE' =>
    'Allow camera access and take a front-camera selfie to clock in.',
  'SELFIE_INVALID' => 'The captured selfie photo is invalid. Please try again.',
  'SELFIE_TOO_LARGE' => 'The selfie photo is too large. Please try again.',
  _ => null,
};
