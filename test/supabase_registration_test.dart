import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/storage/active_workspace_storage.dart';
import 'package:shiftly/features/auth/data/supabase_authentication_service.dart';
import 'package:shiftly/features/auth/domain/entities/authentication_exception.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _AuthClient extends GoTrueClient {
  _AuthClient(this.response) : super(autoRefreshToken: false);
  final AuthResponse response;
  AuthException? error;
  String? redirect;
  String? submittedEmail;

  @override
  Future<AuthResponse> signUp({
    String? email,
    String? phone,
    required String password,
    String? emailRedirectTo,
    Map<String, dynamic>? data,
    String? captchaToken,
    OtpChannel channel = OtpChannel.sms,
  }) async {
    submittedEmail = email;
    redirect = emailRedirectTo;
    if (error case final AuthException value) throw value;
    return response;
  }
}

class _UnusedRepository implements AuthenticationRepository {
  int loads = 0;
  @override
  Future<void> bootstrapProfile({String? fullName, String? phone}) async {}
  @override
  Future<CurrentUser> loadCurrentUser() async {
    loads++;
    throw StateError('Duplicate registration must not load a profile');
  }
}

AuthResponse _response({required bool duplicate}) => AuthResponse(
  user: User.fromJson({
    'id': 'user',
    'aud': 'authenticated',
    'app_metadata': <String, dynamic>{},
    'user_metadata': <String, dynamic>{},
    'created_at': '2026-10-10T00:00:00Z',
    'identities': duplicate
        ? []
        : [
            {
              'id': 'identity',
              'user_id': 'user',
              'identity_id': 'identity',
              'provider': 'email',
              'identity_data': <String, dynamic>{},
            },
          ],
  }),
);

void main() {
  test(
    'masked duplicate stays on registration with an existing-account error',
    () async {
      final client = _AuthClient(_response(duplicate: true));
      final repository = _UnusedRepository();
      final coordinator = SessionCoordinator(
        SupabaseAuthenticationService(client),
        repository,
        MemoryActiveWorkspaceStorage(),
      );
      addTearDown(client.dispose);
      addTearDown(coordinator.close);
      await coordinator.initialize();
      await coordinator.signUp(
        email: ' Existing@Example.com ',
        password: 'password123',
      );
      expect(coordinator.state.status, SessionStatus.failure);
      expect(coordinator.state.failure?.kind, FailureKind.validation);
      expect(
        coordinator.state.failure?.message,
        'An account with this email already exists. Try signing in.',
      );
      expect(repository.loads, 0);
      expect(coordinator.state.verificationEmail, isNull);
    },
  );

  test(
    'new account requires confirmation and uses the standalone landing page',
    () async {
      final client = _AuthClient(_response(duplicate: false));
      addTearDown(client.dispose);
      final result = await SupabaseAuthenticationService(client)
          .signUp(email: ' New@Example.com ', password: 'password123');
      expect(result.emailVerificationRequired, isTrue);
      expect(result.session, isNull);
      expect(client.submittedEmail, 'new@example.com');
      expect(
        client.redirect,
        'https://shiftly-app-smoky.vercel.app/email-confirmed.html',
      );
    },
  );

  test(
    'explicit duplicate errors retain the same actionable message',
    () async {
      final client = _AuthClient(_response(duplicate: true))
        ..error = const AuthException('User already registered');
      addTearDown(client.dispose);
      await expectLater(
        SupabaseAuthenticationService(client)
            .signUp(email: 'existing@example.com', password: 'password123'),
        throwsA(
          isA<AuthenticationException>().having(
            (error) => error.failure.kind,
            'kind',
            FailureKind.validation,
          ),
        ),
      );
    },
  );
}
