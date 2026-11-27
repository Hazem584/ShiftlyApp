import 'package:dio/dio.dart';
import 'package:shiftly/core/error/failure.dart';

FailureKind apiErrorKind(DioException error, int? status) {
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

String apiErrorStatusMessage(int? status) => switch (status) {
  400 || 422 => 'Please check the information you entered.',
  401 => 'Your session has expired. Please sign in again.',
  403 => 'You do not have permission to do that.',
  404 => 'The requested item could not be found.',
  409 =>
    'This information changed or conflicts with an existing record. Refresh its status before trying again.',
  413 => 'The selected file is too large.',
  415 => 'This file type is not supported.',
  429 => 'Too many requests. Please wait and try again.',
  500 || 502 || 503 || 504 =>
    'The service is temporarily unavailable. Please retry.',
  _ =>
    'We could not complete this request. Refresh and check its status before trying again.',
};
