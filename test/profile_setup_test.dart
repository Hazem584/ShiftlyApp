import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/storage/active_workspace_storage.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/auth/domain/entities/auth_session.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_repository.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';
import 'package:shiftly/features/auth/presentation/screens/profile_setup_screen.dart';

class _ProfileAuth implements AuthenticationService {
  final events = StreamController<AuthenticationEvent>.broadcast();
  AuthSession? session = const AuthSession(accessToken: 'token');

  @override
  Stream<AuthenticationEvent> get authStateChanges => events.stream;
  @override
  AuthSession? get currentSession => session;
  @override
  Future<AuthSession?> refreshSession() async => session;
  @override
  Future<void> signOut() async => session = null;
  @override
  Future<AuthenticationResult> signIn({
    required String email,
    required String password,
  }) => throw UnimplementedError();
  @override
  Future<AuthenticationResult> signUp({
    required String email,
    required String password,
  }) => throw UnimplementedError();
  @override
  Future<void> resendSignUpVerification({required String email}) =>
      throw UnimplementedError();
}

class _ProfileRepository implements AuthenticationRepository {
  final bootstrapCompleter = Completer<void>();
  int bootstrapCalls = 0;
  String? fullName;
  String? phone;
  bool completed = false;

  @override
  Future<void> bootstrapProfile({String? fullName, String? phone}) async {
    bootstrapCalls++;
    this.fullName = fullName;
    this.phone = phone;
    await bootstrapCompleter.future;
    completed = true;
  }

  @override
  Future<CurrentUser> loadCurrentUser() async {
    if (!completed) {
      throw const ApiException(
        statusCode: 409,
        code: 'PROFILE_NOT_INITIALIZED',
        message: 'Profile setup is required.',
      );
    }
    return CurrentUser(
      id: 'profile',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      memberships: const [],
    );
  }
}

Future<({SessionCoordinator coordinator, _ProfileRepository repository})>
_pumpProfileSetup(WidgetTester tester) async {
  final auth = _ProfileAuth();
  final repository = _ProfileRepository();
  final coordinator = SessionCoordinator(
    auth,
    repository,
    MemoryActiveWorkspaceStorage(),
  );
  await coordinator.initialize();
  await tester.pumpWidget(
    BlocProvider.value(
      value: coordinator,
      child: MaterialApp(
        theme: AppTheme.lightTheme(),
        home: const ProfileSetupScreen(),
      ),
    ),
  );
  addTearDown(coordinator.close);
  addTearDown(auth.events.close);
  return (coordinator: coordinator, repository: repository);
}

void main() {
  for (final blankPhone in ['', '   ']) {
    testWidgets('blank phone "$blankPhone" is omitted and bootstrap succeeds', (
      tester,
    ) async {
      final setup = await _pumpProfileSetup(tester);
      await tester.enterText(
        find.byKey(const Key('profile-setup-name')),
        '  Hazem Mohammed  ',
      );
      await tester.enterText(
        find.byKey(const Key('profile-setup-phone')),
        blankPhone,
      );
      await tester.tap(find.byKey(const Key('profile-setup-submit')));
      await tester.pump();

      expect(setup.repository.bootstrapCalls, 1);
      expect(setup.repository.fullName, 'Hazem Mohammed');
      expect(setup.repository.phone, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('profile-setup-submit')),
      );
      expect(button.onPressed, isNull);
      await tester.tap(
        find.byKey(const Key('profile-setup-submit')),
        warnIfMissed: false,
      );
      expect(setup.repository.bootstrapCalls, 1);

      setup.repository.bootstrapCompleter.complete();
      await tester.pumpAndSettle();
      expect(
        setup.coordinator.state.status,
        SessionStatus.workspaceSelectionRequired,
      );
    });
  }
}
