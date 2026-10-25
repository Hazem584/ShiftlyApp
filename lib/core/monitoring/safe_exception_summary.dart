import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/monitoring/diagnostic_redaction.dart';

String diagnosticExceptionSummary(Object error) {
  // Dio.toString can contain request/response bodies. Only send safe metadata.
  if (error is DioException) {
    return 'DioException ${error.type.name} status=${error.response?.statusCode ?? 0}';
  }
  if (error is ApiException) {
    final code = error.code;
    return 'ApiException status=${error.statusCode ?? 0}'
        '${code != null && RegExp(r'^[A-Z0-9_]{1,80}$').hasMatch(code) ? ' code=$code' : ''}';
  }
  // Avoid dumping multiline exception bodies; the stack is collected separately.
  final message = error.toString();
  final newline = message.indexOf('\n');
  return redactDiagnostic(
    newline < 0 ? message : message.substring(0, newline),
    2000,
  );
}
