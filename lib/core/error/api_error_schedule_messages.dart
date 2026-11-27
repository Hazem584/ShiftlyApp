import 'package:shiftly/core/error/api_error_extra_messages.dart';

String? apiErrorScheduleMessage(String? code) =>
    switch (code) {
      'SHIFT_TEMPLATE_MINIMUM_WORK_INVALID' =>
        'Minimum work time cannot exceed the shift duration.',
      'SHIFT_TEMPLATE_NAME_CONFLICT' =>
        'An active template already uses this name.',
      'SHIFT_TEMPLATE_NOT_FOUND' => 'That shift template could not be found.',
      'SHIFT_TEMPLATE_ARCHIVED' =>
        'This shift template is archived and read only.',
      'SHIFT_ASSIGNMENT_REQUIRED' || 'ASSIGNMENT_EVIDENCE_UNAVAILABLE' =>
        'Ask your manager to assign a baseline fixed shift.',
      'SHIFT_TEMPLATE_NOT_ASSIGNED' =>
        'This template is not your assigned baseline. Ask your manager for an extra authorization.',
      'SHIFT_TEMPLATE_UNAVAILABLE' =>
        'This shift template is unavailable. Refresh or contact your manager.',
      'ASSIGNMENT_OCCURRENCE_CAPTURED' =>
        'Captured attendance protects this assignment. Choose a later effective date.',
      'SCHEDULE_DAY_LOCKED' =>
        'This day has started or its attendance is already saved. Choose an unused future day.',
      'EXCHANGE_PENDING' =>
        'An active request already reserves one of these dates.',
      'EXCHANGE_LEAVE_CONFLICT' =>
        'The replacement shift overlaps approved leave.',
      'EXCHANGE_EXPIRED' =>
        'This request expired or a check-in window has already opened.',
      'EXCHANGE_NOT_AVAILABLE' =>
        'A swap needs two working occurrences. Coverage needs a colleague with no baseline shift that day.',
      'EXCHANGE_SCHEDULE_CHANGED' =>
        'The agreed schedule changed. Refresh its preview and submit a new request.',
      'SCHEDULE_EXCEPTION_EXISTS' =>
        'Cancel the existing day exception before changing this schedule.',
      'SCHEDULE_EXCEPTION_OVERLAP' =>
        'This change overlaps another assigned day or authorized extra shift.',
      'SCHEDULE_EXCEPTION_CONFLICT' ||
      'SCHEDULE_EXCEPTION_IDEMPOTENCY_CONFLICT' =>
        'The schedule changed. Refresh its exceptions and check your last submission before trying again.',
      'ASSIGNMENT_EXTRA_OCCURRENCE_CONFLICT' =>
        'This assignment overlaps an authorized extra. Review the employee schedule.',
      'ATTENDANCE_OCCURRENCE_ALREADY_USED' =>
        'This occurrence has already been used and cannot be reopened.',
      'WORK_PATTERN_EFFECTIVE_DATE_IN_PAST' =>
        'Choose today or a future date in the workspace timezone.',
      'WORK_PATTERN_INVALID_WEEKDAYS' => 'Select one or more unique weekdays.',
      'WORK_PATTERN_INVALID_DATE' => 'Choose a valid effective date.',
      'WORK_PATTERN_EMPLOYEE_NOT_ACTIVE' =>
        'Only active employees can receive a new work pattern.',
      'WORK_PATTERN_NOT_FOUND' => 'That employee work pattern is unavailable.',
      'WORK_PATTERN_CONFLICT' =>
        'The work pattern changed. Refresh before trying again.',
      'NOT_EXPECTED_WORKDAY' =>
        'You are not scheduled to work on this operational date.',
      'SHIFT_TEMPLATE_NOT_ELIGIBLE' =>
        'This template is outside its current check-in window.',
      _ => null,
    } ??
    apiErrorExtraMessage(code);
