import 'package:shiftly/core/error/api_error_attendance_messages.dart';
import 'package:shiftly/core/error/api_error_chat_messages.dart';
import 'package:shiftly/core/error/api_error_schedule_messages.dart';

String? apiErrorCodeMessage(String? code) =>
    switch (code) {
      'PROFILE_NOT_INITIALIZED' => 'Complete your profile to continue.',
      'PROFILE_EMAIL_CONFLICT' =>
        'This email is linked to another account. Contact support to complete setup.',
      'INVALID_CREDENTIALS' => 'The email or password is incorrect.',
      'RATE_LIMIT_EXCEEDED' => 'Too many requests. Please wait and try again.',
      'EMPLOYEE_NOT_FOUND' => 'That employee could not be found.',
      'EMPTY_UPDATE' => 'Choose a change before saving.',
      'MEMBER_ALREADY_EXISTS' => 'This person is already a workspace member.',
      'INVITATION_ALREADY_PENDING' =>
        'A pending invitation already exists for this email.',
      'INVALID_INVITATION' => 'This invitation is not valid.',
      'INVITATION_ALREADY_USED' => 'This invitation has already been used.',
      'INVITATION_EMAIL_MISMATCH' =>
        'This invitation belongs to a different email address.',
      'INVITATION_EXPIRED' => 'This invitation has expired.',
      'NOTIFICATION_NOT_FOUND' => 'That notification is no longer available.',
      'REJECTION_REASON_REQUIRED' => 'Enter a reason for rejection.',
      'REJECTION_REASON_NOT_ALLOWED' =>
        'A rejection reason is only allowed when rejecting.',
      'WORKSPACE_ACCESS_DENIED' =>
        'Your workspace membership does not allow this action.',
      'WORKSPACE_TIMEZONE_INVALID' =>
        'The workspace timezone is invalid. Ask a manager to correct it.',
      'INVALID_DATE_RANGE' => 'The start date must not be after the end date.',
      _ => null,
    } ??
    apiErrorAttendanceMessage(code) ??
    apiErrorScheduleMessage(code) ??
    apiErrorChatMessage(code);
