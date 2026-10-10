import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/auth/domain/entities/auth_session.dart';
import 'package:shiftly/features/auth/domain/entities/authentication_exception.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthenticationService implements AuthenticationService {
  SupabaseAuthenticationService(this._auth);

  final GoTrueClient _auth;

  static String get _emailRedirect => kIsWeb
      ? '${Uri.base.origin}/email-confirmed.html'
      : const String.fromEnvironment(
          'AUTH_EMAIL_REDIRECT_URL',
          defaultValue:
              'https://shiftly-app-smoky.vercel.app/email-confirmed.html',
        );

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
        emailRedirectTo: _emailRedirect,
      );
      // Supabase can mask duplicate confirmed accounts with an empty identity
      // list instead of returning an error. This is not a new registration.
      if (response.session == null &&
          response.user?.identities?.isEmpty == true) {
        throw const AuthenticationException(
          Failure(
            message:
                'An account with this email already exists. Try signing in.',
            kind: FailureKind.validation,
          ),
        );
      }
      return AuthenticationResult(
        session: _mapSession(response.session),
        emailVerificationRequired:
            response.user != null && response.session == null,
      );
    } on AuthenticationException {
      rethrow;
    } on AuthException catch (error) {
      throw AuthenticationException(_safeFailure(error));
    } on TimeoutException {
      throw const AuthenticationException(
        Failure(
          message: 'The request timed out. Please try again.',
          kind: FailureKind.timeout,
        ),
      );
    } catch (_) {
      throw const AuthenticationException(
        Failure(
          message: 'Unable to create your account. Check your connection and try again.',
          kind: FailureKind.network,
        ),
      );
    }
  }

  @override
  Future<void> resendSignUpVerification({required String email}) async {
    try {
      await _auth.resend(
        type: OtpType.signup,
        email: email.trim().toLowerCase(),
        emailRedirectTo: _emailRedirect,
      );
    } on AuthException catch (error) {
      throw AuthenticationException(_safeFailure(error));
    } on TimeoutException {
      throw const AuthenticationException(
        Failure(
          message: 'The request timed out. Please try again.',
          kind: FailureKind.timeout,
        ),
      );
    } catch (_) {
      throw const AuthenticationException(
        Failure(
          message: 'Unable to resend the email. Check your connection and try again.',
          kind: FailureKind.network,
        ),
      );
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
    if (error.code == 'user_already_exists' ||
        error.code == 'email_exists' ||
        normalized.contains('already registered') ||
        normalized.contains('already exists') ||
        normalized.contains('user_already_exists')) {
      return const Failure(
        message: 'An account with this email already exists. Try signing in.',
        kind: FailureKind.validation,
      );
    }
    if (normalized.contains('weak') ||
        normalized.contains('password') && normalized.contains('characters')) {
      return const Failure(
        message: 'Choose a stronger password with at least 8 characters.',
        kind: FailureKind.validation,
      );
    }
    return const Failure(
      message: 'Authentication failed. Please try again.',
      kind: FailureKind.authentication,
    );
  }
}
