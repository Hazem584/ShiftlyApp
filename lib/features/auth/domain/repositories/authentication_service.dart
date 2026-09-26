import 'package:shiftly/features/auth/domain/entities/auth_session.dart';

abstract interface class AuthenticationService {
  AuthSession? get currentSession;

  Future<AuthenticationResult> signIn({
    required String email,
    required String password,
  });

  Future<AuthenticationResult> signUp({
    required String email,
    required String password,
  });

  Future<void> resendSignUpVerification({required String email});

  Future<AuthSession?> refreshSession();

  Future<void> signOut();

  Stream<AuthenticationEvent> get authStateChanges;
}
