import 'package:shiftly/features/auth/domain/entities/auth_session.dart';

class AuthenticationResult {
  const AuthenticationResult({
    required this.session,
    this.emailVerificationRequired = false,
  });

  final AuthSession? session;
  final bool emailVerificationRequired;
}
