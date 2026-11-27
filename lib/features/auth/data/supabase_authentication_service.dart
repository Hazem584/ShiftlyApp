import 'dart:async';

import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/auth/data/supabase_auth_mapper.dart';
import 'package:shiftly/features/auth/data/supabase_auth_signup.dart';
import 'package:shiftly/features/auth/domain/entities/auth_session.dart';
import 'package:shiftly/features/auth/domain/entities/authentication_exception.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthenticationService implements AuthenticationService {
  SupabaseAuthenticationService(this._auth);
  final GoTrueClient _auth;

  @override
  AuthSession? get currentSession =>
      SupabaseAuthMapper.mapSession(_auth.currentSession);

  @override
  Stream<AuthenticationEvent> get authStateChanges =>
      _auth.onAuthStateChange.map(SupabaseAuthMapper.mapEvent);

  @override
  Future<AuthenticationResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      return AuthenticationResult(
        session: SupabaseAuthMapper.mapSession(res.session),
      );
    } on AuthException catch (error) {
      throw AuthenticationException(mapSupabaseAuthFailure(error));
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
  }) => runSupabaseSignUp(_auth, email: email, password: password);

  @override
  Future<void> resendSignUpVerification({required String email}) =>
      runSupabaseResendVerification(_auth, email: email);

  @override
  Future<AuthSession?> refreshSession() async {
    try {
      final res = await _auth.refreshSession();
      return SupabaseAuthMapper.mapSession(res.session);
    } catch (error) {
      throw SupabaseAuthMapper.mapRefreshError(error);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut(scope: SignOutScope.local);
    } catch (_) {}
  }
}
