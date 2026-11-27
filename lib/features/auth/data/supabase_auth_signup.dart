import 'dart:async';

import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/auth/data/supabase_auth_mapper.dart';
import 'package:shiftly/features/auth/domain/entities/auth_session.dart';
import 'package:shiftly/features/auth/domain/entities/authentication_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<AuthenticationResult> runSupabaseSignUp(
  GoTrueClient auth, {
  required String email,
  required String password,
}) async {
  try {
    final res = await auth.signUp(
      email: email.trim().toLowerCase(),
      password: password,
      emailRedirectTo: SupabaseAuthMapper.emailRedirect,
    );
    if (res.session == null && res.user?.identities?.isEmpty == true) {
      throw const AuthenticationException(
        Failure(
          message: 'An account with this email already exists. Try signing in.',
          kind: FailureKind.validation,
        ),
      );
    }
    return AuthenticationResult(
      session: SupabaseAuthMapper.mapSession(res.session),
      emailVerificationRequired: res.user != null && res.session == null,
    );
  } on AuthenticationException {
    rethrow;
  } on AuthException catch (error) {
    throw AuthenticationException(mapSupabaseAuthFailure(error));
  } on TimeoutException {
    throw supabaseTimeoutException();
  } catch (_) {
    throw const AuthenticationException(
      Failure(
        message:
            'Unable to create your account. Check your connection and try again.',
        kind: FailureKind.network,
      ),
    );
  }
}

Future<void> runSupabaseResendVerification(
  GoTrueClient auth, {
  required String email,
}) async {
  try {
    await auth.resend(
      type: OtpType.signup,
      email: email.trim().toLowerCase(),
      emailRedirectTo: SupabaseAuthMapper.emailRedirect,
    );
  } on AuthException catch (error) {
    throw AuthenticationException(mapSupabaseAuthFailure(error));
  } on TimeoutException {
    throw supabaseTimeoutException();
  } catch (_) {
    throw const AuthenticationException(
      Failure(
        message:
            'Unable to resend the email. Check your connection and try again.',
        kind: FailureKind.network,
      ),
    );
  }
}
