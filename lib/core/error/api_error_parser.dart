import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';

abstract final class ApiErrorParser {
  static ApiException parse(Object error) {
    if (error is ApiException) return error;
    if (error is! DioException) {
      return const ApiException(
        message: 'Something went wrong. Please try again.',
      );
    }
    final status = error.response?.statusCode;
    final body = error.response?.data;
    final data = body is Map ? Map<String, Object?>.from(body) : null;
    final rawMessage = data?['message'];
    final validation = rawMessage is List
        ? rawMessage.whereType<String>().toList(growable: false)
        : const <String>[];
    final code = data?['code'] is String ? data!['code'] as String : null;
    final requestId = data?['requestId'] is String
        ? data!['requestId'] as String
        : error.response?.headers.value('x-request-id');
    final path = data?['path'] is String ? data!['path'] as String : null;
    final kind = _kind(error, status);
    return ApiException(
      statusCode: status,
      code: code,
      message: _friendlyMessage(error, status, code, validation),
      validationMessages: validation,
      requestId: requestId,
      path: path,
      kind: kind,
    );
  }

  static FailureKind _kind(DioException error, int? status) {
    if (error.type == DioExceptionType.cancel) return FailureKind.cancelled;
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return FailureKind.timeout;
    }
    if (error.type == DioExceptionType.connectionError) {
      return FailureKind.network;
    }
    if (status == 401) return FailureKind.authentication;
    if (status == 403) return FailureKind.authorization;
    if (status == 400 ||
        status == 409 ||
        status == 413 ||
        status == 415 ||
        status == 422) {
      return FailureKind.validation;
    }
    if (status != null && status >= 500) return FailureKind.server;
    return FailureKind.unknown;
  }

  static String _friendlyMessage(
    DioException error,
    int? status,
    String? code,
    List<String> validation,
  ) {
    if (error.type == DioExceptionType.cancel) return 'Request cancelled.';
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'The request timed out. Please try again.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'You appear to be offline. Check your connection and retry.';
    }
    if (validation.isNotEmpty) return validation.first;
    return switch (code) {
      'PROFILE_NOT_INITIALIZED' => 'Complete your profile to continue.',
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
      'SHIFT_EMPLOYEE_INVALID' =>
        'Choose an active employee from this workspace.',
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
      'ATTENDANCE_ALREADY_EXISTS' =>
        'You have already clocked in for this shift.',
      'ATTENDANCE_ALREADY_CLOCKED_OUT' =>
        'You have already clocked out for this shift.',
      'ATTENDANCE_REJECTED' => 'Rejected attendance cannot be clocked out.',
      'ATTENDANCE_ALREADY_REVIEWED' =>
        'This attendance request has already been reviewed.',
      'ATTENDANCE_NOT_FOUND' => 'That attendance record could not be found.',
      'LEAVE_EMPLOYEE_NOT_ACTIVE' =>
        'Only active employees can manage leave requests.',
      'LEAVE_REQUEST_INVALID_TIME_RANGE' =>
        'Leave end must be after its start.',
      'LEAVE_REQUEST_TOO_LONG' =>
        'A leave request cannot be longer than 365 days.',
      'LEAVE_REQUEST_OVERLAP' =>
        'This leave overlaps another pending or approved request.',
      'LEAVE_REQUEST_NOT_FOUND' => 'That leave request could not be found.',
      'LEAVE_REQUEST_ALREADY_REVIEWED' =>
        'This leave request has already been reviewed.',
      'LEAVE_REQUEST_ALREADY_CANCELLED' =>
        'This leave request has already been cancelled.',
      'LEAVE_REQUEST_NOT_PENDING' =>
        'Only pending leave requests can be changed.',
      'NOTIFICATION_NOT_FOUND' => 'That notification is no longer available.',
      'REJECTION_REASON_REQUIRED' => 'Enter a reason for rejection.',
      'REJECTION_REASON_NOT_ALLOWED' =>
        'A rejection reason is only allowed when rejecting.',
      'WORKSPACE_ACCESS_DENIED' =>
        'Your workspace membership does not allow this action.',
      'INVALID_DATE_RANGE' => 'The start date must not be after the end date.',
      'CHAT_GROUP_ARCHIVED' => 'This chat group is archived and read only.',
      'CHAT_GROUP_NOT_FOUND' => 'That chat group could not be found.',
      'CHAT_CURSOR_INVALID' => 'Messages changed. Refresh the conversation.',
      'CHAT_CLIENT_MESSAGE_ID_CONFLICT' =>
        'This message conflicts with an earlier send attempt.',
      'CHAT_READ_POSITION_BACKWARDS' =>
        'Your read position is already ahead of that message.',
      'CHAT_READ_POSITION_CONFLICT' =>
        'The read position changed. Refreshing will synchronize it.',
      _ => switch (status) {
        400 => 'Please check the information you entered.',
        401 => 'Your session has expired. Please sign in again.',
        403 => 'You do not have permission to do that.',
        404 => 'The requested item could not be found.',
        409 => 'This action conflicts with the current state.',
        413 => 'The selected file is too large.',
        415 => 'This file type is not supported.',
        422 => 'Please check the information you entered.',
        429 => 'Too many requests. Please wait and try again.',
        500 ||
        502 ||
        503 ||
        504 => 'The service is temporarily unavailable. Please retry.',
        _ => 'Something went wrong. Please try again.',
      },
    };
  }
}
