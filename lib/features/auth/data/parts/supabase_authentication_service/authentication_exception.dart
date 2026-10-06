part of '../../supabase_authentication_service.dart';

class AuthenticationException implements Exception {
  const AuthenticationException(this.failure);

  final Failure failure;
}
