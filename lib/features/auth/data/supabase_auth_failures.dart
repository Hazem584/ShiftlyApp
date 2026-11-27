import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/auth/domain/entities/authentication_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Failure mapSupabaseAuthFailure(AuthException error) {
  final norm = error.message.toLowerCase();
  if (norm.contains('invalid login credentials') ||
      norm.contains('invalid credentials')) {
    return const Failure(
      message: 'The email or password is incorrect.',
      kind: FailureKind.authentication,
    );
  }
  if (norm.contains('email not confirmed')) {
    return const Failure(
      message: 'Verify your email before signing in.',
      kind: FailureKind.authentication,
    );
  }
  if (norm.contains('rate') || norm.contains('too many')) {
    return const Failure(
      message: 'Too many attempts. Please wait and try again.',
    );
  }
  if (error.code == 'user_already_exists' ||
      error.code == 'email_exists' ||
      norm.contains('already registered') ||
      norm.contains('already exists') ||
      norm.contains('user_already_exists')) {
    return const Failure(
      message: 'An account with this email already exists. Try signing in.',
      kind: FailureKind.validation,
    );
  }
  if (norm.contains('weak') ||
      (norm.contains('password') && norm.contains('characters'))) {
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

AuthenticationException supabaseTimeoutException() =>
    const AuthenticationException(
      Failure(
        message: 'The request timed out. Please try again.',
        kind: FailureKind.timeout,
      ),
    );
