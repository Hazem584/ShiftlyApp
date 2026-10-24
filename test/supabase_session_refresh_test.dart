import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/auth/data/supabase_authentication_service.dart';
import 'package:shiftly/features/auth/domain/entities/authentication_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _RefreshClient extends GoTrueClient {
  _RefreshClient(this.error) : super(autoRefreshToken: false);
  final Object error;
  SignOutScope? signedOutScope;
  @override
  Future<AuthResponse> refreshSession([String? refreshToken]) async =>
      throw error;
  @override
  Future<void> signOut({SignOutScope scope = SignOutScope.local}) async {
    signedOutScope = scope;
  }
}

void main() {
  Future<void> check(Object error, FailureKind kind) async {
    final client = _RefreshClient(error);
    addTearDown(client.dispose);
    await expectLater(
      SupabaseAuthenticationService(client).refreshSession(),
      throwsA(
        isA<AuthenticationException>().having(
          (e) => e.failure.kind,
          'failure kind',
          kind,
        ),
      ),
    );
    expect(client.signedOutScope, isNull);
  }

  test(
    'a retryable refresh fetch failure is network failure, not expiration',
    () => check(AuthRetryableFetchException(), FailureKind.network),
  );
  test(
    'an auth-server outage does not expire a session',
    () => check(
      const AuthApiException('service unavailable', statusCode: '503'),
      FailureKind.server,
    ),
  );
  test(
    'an auth rate limit is retryable',
    () => check(
      const AuthApiException('rate limited', statusCode: '429'),
      FailureKind.network,
    ),
  );
  test(
    'a timeout does not expire a session',
    () => check(TimeoutException('timeout'), FailureKind.timeout),
  );
  test(
    'a revoked refresh token really requires signing in again',
    () => check(
      const AuthApiException(
        'token not found',
        code: 'refresh_token_not_found',
        statusCode: '400',
      ),
      FailureKind.authentication,
    ),
  );
  test('normal sign-out affects only this device', () async {
    final client = _RefreshClient(StateError('unused'));
    addTearDown(client.dispose);
    await SupabaseAuthenticationService(client).signOut();
    expect(client.signedOutScope, SignOutScope.local);
  });
}
