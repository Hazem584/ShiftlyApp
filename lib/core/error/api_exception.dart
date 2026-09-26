import 'package:shiftly/core/error/failure.dart';

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.validationMessages = const [],
    this.requestId,
    this.path,
    this.kind = FailureKind.unknown,
  });

  final int? statusCode;
  final String? code;
  final String message;
  final List<String> validationMessages;
  final String? requestId;
  final String? path;
  final FailureKind kind;

  Failure toFailure() =>
      Failure(message: message, kind: kind, requestId: requestId);

  @override
  String toString() =>
      'ApiException($statusCode, $code, requestId: $requestId)';
}
