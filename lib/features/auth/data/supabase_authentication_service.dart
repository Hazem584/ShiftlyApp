import 'dart:async';

import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/auth/domain/entities/auth_session.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthenticationException implements Exception {
  const AuthenticationException(this.failure);

  final Failure failure;
}

class SupabaseAuthenticationService implements AuthenticationService {
  SupabaseAuthenticationService(this._auth);

  final GoTrueClient _auth;

  @override
  AuthSession? get currentSession => _mapSession(_auth.currentSession);

  @override
  Stream<AuthenticationEvent> get authStateChanges =>
      _auth.onAuthStateChange.map(
        (event) => AuthenticationEvent(switch (event.event) {
          AuthChangeEvent.signedIn => AuthenticationEventType.signedIn,
          AuthChangeEvent.signedOut => AuthenticationEventType.signedOut,
          AuthChangeEvent.tokenRefreshed =>
            AuthenticationEventType.tokenRefreshed,
          _ => AuthenticationEventType.other,
        }),
      );

  @override
  Future<AuthenticationResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      return AuthenticationResult(session: _mapSession(response.session));
    } on AuthException catch (error) {
      throw AuthenticationException(_safeFailure(error));
    } catch (_) {
      throw const AuthenticationException(
        Failure(
          message: 'Unable to sign in. Check your connection and try again.',
          kind: FailureKind.network,
        ),
      );
    }
  }

  @override
  Future<AuthenticationResult> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
      );
      return AuthenticationResult(
        session: _mapSession(response.session),
        emailVerificationRequired:
            response.user != null && response.session == null,
      );
    } on AuthException catch (error) {
      throw AuthenticationException(_safeFailure(error));
    }
  }

  @override
  Future<AuthSession?> refreshSession() async {
    try {
      final response = await _auth.refreshSession();
      return _mapSession(response.session);
    } on AuthException catch (error) {
      throw AuthenticationException(_safeFailure(error));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut(scope: SignOutScope.local);
    } catch (_) {
      // Local session cleanup remains Supabase Auth's responsibility.
    }
  }

  static AuthSession? _mapSession(Session? session) =>
      session == null ? null : AuthSession(accessToken: session.accessToken);

  static Failure _safeFailure(AuthException error) {
    final normalized = error.message.toLowerCase();
    if (normalized.contains('invalid login credentials') ||
        normalized.contains('invalid credentials')) {
      return const Failure(
        message: 'The email or password is incorrect.',
        kind: FailureKind.authentication,
      );
    }
    if (normalized.contains('email not confirmed')) {
      return const Failure(
        message: 'Verify your email before signing in.',
        kind: FailureKind.authentication,
      );
    }
    if (normalized.contains('rate') || normalized.contains('too many')) {
      return const Failure(
        message: 'Too many attempts. Please wait and try again.',
      );
    }
    return const Failure(
      message: 'Authentication failed. Please try again.',
      kind: FailureKind.authentication,
    );
  }
}
