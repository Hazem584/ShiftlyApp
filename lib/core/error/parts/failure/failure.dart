part of '../../failure.dart';

class Failure {
  const Failure({
    required this.message,
    this.kind = FailureKind.unknown,
    this.requestId,
    this.code,
    this.statusCode,
  });

  final String? code;
  final int? statusCode;
  final String message;
  final FailureKind kind;
  final String? requestId;
}
