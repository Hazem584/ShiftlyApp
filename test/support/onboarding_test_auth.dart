import 'dart:async';

import 'package:shiftly/features/auth/domain/entities/auth_session.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';

class OnboardingTestAuth implements AuthenticationService {
  AuthSession? session;
  final events = StreamController<AuthenticationEvent>.broadcast();
  @override
  Stream<AuthenticationEvent> get authStateChanges => events.stream;
  @override
  AuthSession? get currentSession => session;
  @override
  Future<AuthSession?> refreshSession() async => session;
  @override
  Future<void> signOut() async {
    session = null;
  }

  @override
  Future<AuthenticationResult> signIn({
    required String email,
    required String password,
  }) async {
    session = const AuthSession(accessToken: 'isolated-test-token');
    return AuthenticationResult(session: session);
  }

  @override
  Future<AuthenticationResult> signUp({
    required String email,
    required String password,
  }) => signIn(email: email, password: password);
  @override
  Future<void> resendSignUpVerification({required String email}) async {}
}
