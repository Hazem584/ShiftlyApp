import 'package:shiftly/core/error/failure.dart';

class AuthenticationException implements Exception {
  const AuthenticationException(this.failure);

  final Failure failure;
}
