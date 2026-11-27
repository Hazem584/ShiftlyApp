import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/auth/domain/entities/auth_session.dart';
import 'package:shiftly/features/auth/domain/entities/authentication_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

export 'package:shiftly/features/auth/data/supabase_auth_failures.dart';

class SupabaseAuthMapper {
  static String get emailRedirect => kIsWeb
      ? '${Uri.base.origin}/email-confirmed.html'
      : const String.fromEnvironment(
          'AUTH_EMAIL_REDIRECT_URL',
          defaultValue:
              'https://shiftly-app-smoky.vercel.app/email-confirmed.html',
        );

  static AuthSession? mapSession(Session? session) =>
      session == null ? null : AuthSession(accessToken: session.accessToken);

  static AuthenticationEvent mapEvent(AuthState event) => AuthenticationEvent(
    switch (event.event) {
      AuthChangeEvent.signedIn => AuthenticationEventType.signedIn,
      AuthChangeEvent.signedOut => AuthenticationEventType.signedOut,
      AuthChangeEvent.tokenRefreshed => AuthenticationEventType.tokenRefreshed,
      _ => AuthenticationEventType.other,
    },
  );

  static AuthenticationException mapRefreshError(Object error) {
    if (error is AuthException) {
      final status = int.tryParse(error.statusCode ?? '');
      if (error is AuthRetryableFetchException ||
          status == null ||
          status == 429 ||
          status >= 500) {
        return AuthenticationException(
          Failure(
            message: 'Could not refresh your session. Check your connection and retry.',
            kind: status != null && status >= 500
                ? FailureKind.server
                : FailureKind.network,
            code: 'SESSION_REFRESH_UNAVAILABLE',
            statusCode: status,
          ),
        );
      }
      return AuthenticationException(
        Failure(
          message: 'Your session has expired. Please sign in again.',
          kind: FailureKind.authentication,
          code: error.code,
          statusCode: status,
        ),
      );
    }
    return AuthenticationException(
      Failure(
        message:
            'Could not refresh your session. Check your connection and retry.',
        kind: error is TimeoutException
            ? FailureKind.timeout
            : FailureKind.network,
        code: 'SESSION_REFRESH_UNAVAILABLE',
      ),
    );
  }
}
