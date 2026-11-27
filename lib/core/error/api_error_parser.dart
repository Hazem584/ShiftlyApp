import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_error_code_messages.dart';
import 'package:shiftly/core/error/api_error_status_messages.dart';
import 'package:shiftly/core/error/api_exception.dart';

abstract final class ApiErrorParser {
  static ApiException parse(Object error) {
    if (error is ApiException) return error;
    if (error is! DioException) {
      return ApiException(
        message: error is FormatException
            ? 'We could not read the latest information. Refresh to load it again.'
            : 'We could not complete this request. Refresh and check its status before trying again.',
      );
    }
    if (error.response == null && error.error is ApiException) {
      return error.error! as ApiException;
    }
    final status = error.response?.statusCode;
    final data = _bodyMap(error.response?.data);
    final rawMessage = data?['message'];
    final validation = rawMessage is List
        ? rawMessage.whereType<String>().toList(growable: false)
        : const <String>[];
    final code = data?['code'] is String ? data!['code'] as String : null;
    final requestId = data?['requestId'] is String
        ? data!['requestId'] as String
        : error.response?.headers.value('x-request-id');
    final path = data?['path'] is String ? data!['path'] as String : null;
    return ApiException(
      statusCode: status,
      code: code,
      message: _friendlyMessage(error, status, code, validation),
      validationMessages: validation,
      requestId: requestId,
      path: path,
      kind: apiErrorKind(error, status),
    );
  }

  static Map<String, Object?>? _bodyMap(Object? body) {
    if (body is! Map) return null;
    try {
      return Map<String, Object?>.from(body);
    } catch (_) {
      return null;
    }
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
    return apiErrorCodeMessage(code) ?? apiErrorStatusMessage(status);
  }
}
