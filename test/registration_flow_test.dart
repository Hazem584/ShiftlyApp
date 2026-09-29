import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/app.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/storage/active_workspace_storage.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';
import 'package:shiftly/features/auth/data/supabase_authentication_service.dart';
import 'package:shiftly/features/auth/domain/entities/auth_session.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_repository.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';
import 'package:shiftly/features/notifications/data/mock_notification_repository.dart';
import 'package:shiftly/features/dashboard/data/mock_dashboard_repository.dart';
import 'package:shiftly/features/employees/data/mock_employee_repository.dart';

class _RegistrationAuth implements AuthenticationService {
  final events = StreamController<AuthenticationEvent>.broadcast();
  AuthenticationResult result = const AuthenticationResult(
    session: null,
    emailVerificationRequired: true,
  );
  Object? signUpError;
  Completer<AuthenticationResult>? pendingSignUp;
  Completer<void>? pendingResend;
  Object? resendError;
  AuthSession? session;
  int signUpCalls = 0;
  int resendCalls = 0;
  int signOutCalls = 0;
  String? email;

  @override
  Stream<AuthenticationEvent> get authStateChanges => events.stream;
  @override
  AuthSession? get currentSession => session;
  @override
  Future<AuthSession?> refreshSession() async => session;

  @override
  Future<AuthenticationResult> signUp({
    required String email,
    required String password,
  }) async {
    signUpCalls += 1;
    this.email = email;
    if (signUpError case final Object error) throw error;
    final response = await (pendingSignUp?.future ?? Future.value(result));
    session = response.session;
    return response;
  }

  @override
  Future<void> resendSignUpVerification({required String email}) async {
    resendCalls += 1;
    if (resendError case final Object error) throw error;
    if (pendingResend case final completer?) await completer.future;
  }

  @override
  Future<AuthenticationResult> signIn({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
    session = null;
  }
}

class _RegistrationRepository implements AuthenticationRepository {
  int loadCalls = 0;

  @override
  Future<void> bootstrapProfile({String? fullName, String? phone}) async {}

  @override
  Future<CurrentUser> loadCurrentUser() async {
    loadCalls += 1;
    return CurrentUser(
      id: 'profile',
      email: 'invited@example.test',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      memberships: const [],
    );
  }
}

({SessionCoordinator coordinator, _RegistrationRepository repository})
_coordinator(_RegistrationAuth auth) {
  final repository = _RegistrationRepository();
  return (
    coordinator: SessionCoordinator(
      auth,
      repository,
      MemoryActiveWorkspaceStorage(),
    ),
    repository: repository,
  );
}

void main() {
  test('immediate-session sign-up resolves the backend account', () async {
    final auth = _RegistrationAuth()
      ..result = const AuthenticationResult(
        session: AuthSession(accessToken: 'opaque-session'),
      );
    final setup = _coordinator(auth);
    addTearDown(setup.coordinator.close);
    addTearDown(auth.events.close);
    await setup.coordinator.initialize();

    await setup.coordinator.signUp(
      email: ' Invited@Example.Test ',
      password: 'not-recorded',
    );

    expect(auth.email, 'invited@example.test');
    expect(setup.repository.loadCalls, 1);
    expect(
      setup.coordinator.state.status,
      SessionStatus.workspaceSelectionRequired,
    );
  });

  test('verification-required sign-up does not call NestJS', () async {
    final auth = _RegistrationAuth();
    final setup = _coordinator(auth);
    addTearDown(setup.coordinator.close);
    addTearDown(auth.events.close);
    await setup.coordinator.initialize();

    await setup.coordinator.signUp(
      email: ' Invited@Example.Test ',
      password: 'not-recorded',
    );

    expect(setup.repository.loadCalls, 0);
    expect(
      setup.coordinator.state.status,
      SessionStatus.emailVerificationRequired,
    );
    expect(setup.coordinator.state.verificationEmail, 'invited@example.test');
  });

  for (final failure in <Failure>[
    const Failure(
      message: 'An account with this email already exists. Try signing in.',
      kind: FailureKind.validation,
    ),
    const Failure(
      message: 'Choose a stronger password with at least 8 characters.',
      kind: FailureKind.validation,
    ),
    const Failure(
      message: 'Too many attempts. Please wait and try again.',
      kind: FailureKind.validation,
    ),
    const Failure(
      message:
          'Unable to create your account. Check your connection and try again.',
      kind: FailureKind.network,
    ),
    const Failure(
      message: 'The request timed out. Please try again.',
      kind: FailureKind.timeout,
    ),
  ]) {
    test(
      'sign-up safely reports ${failure.kind}: ${failure.message}',
      () async {
        final auth = _RegistrationAuth()
          ..signUpError = AuthenticationException(failure);
        final setup = _coordinator(auth);
        addTearDown(setup.coordinator.close);
        addTearDown(auth.events.close);
        await setup.coordinator.initialize();

        await setup.coordinator.signUp(
          email: 'person@example.test',
          password: 'not-recorded',
        );

        expect(setup.coordinator.state.status, SessionStatus.failure);
        expect(setup.coordinator.state.failure?.message, failure.message);
        expect(setup.repository.loadCalls, 0);
      },
    );
  }

  test('logout invalidates an in-flight sign-up', () async {
    final pending = Completer<AuthenticationResult>();
    final auth = _RegistrationAuth()..pendingSignUp = pending;
    final setup = _coordinator(auth);
    addTearDown(setup.coordinator.close);
    addTearDown(auth.events.close);
    await setup.coordinator.initialize();

    final signUp = setup.coordinator.signUp(
      email: 'person@example.test',
      password: 'not-recorded',
    );
    await Future<void>.delayed(Duration.zero);
    await setup.coordinator.signOut();
    pending.complete(
      const AuthenticationResult(
        session: null,
        emailVerificationRequired: true,
      ),
    );
    await signUp;

    expect(setup.coordinator.state.status, SessionStatus.unauthenticated);
    expect(setup.coordinator.state.verificationEmail, isNull);
    expect(setup.repository.loadCalls, 0);
  });

  test('auth-state sign-in after verification resolves normally', () async {
    final auth = _RegistrationAuth();
    final setup = _coordinator(auth);
    addTearDown(setup.coordinator.close);
    addTearDown(auth.events.close);
    await setup.coordinator.initialize();
    await setup.coordinator.signUp(
      email: 'invited@example.test',
      password: 'not-recorded',
    );

    auth.session = const AuthSession(accessToken: 'opaque-session');
    auth.events.add(
      const AuthenticationEvent(AuthenticationEventType.signedIn),
    );
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(setup.repository.loadCalls, 1);
    expect(
      setup.coordinator.state.status,
      SessionStatus.workspaceSelectionRequired,
    );
  });

  testWidgets(
    'registration validates input and prevents duplicate submission',
    (tester) async {
      final auth = _RegistrationAuth()
        ..pendingSignUp = Completer<AuthenticationResult>();
      final setup = _coordinator(auth);
      await setup.coordinator.initialize();
      await tester.pumpWidget(
        ShiftlyApp(
          sessionCoordinator: setup.coordinator,
          notificationRepository: MockNotificationRepository(),
          dashboardRepository: MockDashboardRepository(
            employeeRepository: MockEmployeeRepository(delay: Duration.zero),
            delay: Duration.zero,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      addTearDown(auth.events.close);

      await tester.tap(find.byKey(const Key('login-create-account')));
      await tester.pumpAndSettle();
      expect(find.text('Create your Shiftly account'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('register-email')),
        'not-an-email',
      );
      await tester.enterText(
        find.byKey(const Key('register-password')),
        'short',
      );
      await tester.enterText(
        find.byKey(const Key('register-confirm-password')),
        'different',
      );
      await tester.tap(find.byKey(const Key('register-submit')));
      await tester.pump();
      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(find.text('Use at least 8 characters'), findsOneWidget);
      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(auth.signUpCalls, 0);

      await tester.enterText(
        find.byKey(const Key('register-email')),
        ' Invited@Example.Test ',
      );
      await tester.enterText(
        find.byKey(const Key('register-password')),
        'strong-password',
      );
      await tester.enterText(
        find.byKey(const Key('register-confirm-password')),
        'strong-password',
      );
      await tester.tap(find.byKey(const Key('register-submit')));
      await tester.pump();
      expect(auth.signUpCalls, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('register-submit')))
            .onPressed,
        isNull,
      );
      await tester.tap(
        find.byKey(const Key('register-submit')),
        warnIfMissed: false,
      );
      expect(auth.signUpCalls, 1);

      auth.pendingSignUp!.complete(
        const AuthenticationResult(
          session: null,
          emailVerificationRequired: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('invited@example.test'), findsOneWidget);
    },
  );

  testWidgets('verification resend is guarded and back returns to login', (
    tester,
  ) async {
    final auth = _RegistrationAuth()..pendingResend = Completer<void>();
    final setup = _coordinator(auth);
    await setup.coordinator.initialize();
    await setup.coordinator.signUp(
      email: 'Invited@Example.Test',
      password: 'not-recorded',
    );
    await tester.pumpWidget(
      ShiftlyApp(
        sessionCoordinator: setup.coordinator,
        notificationRepository: MockNotificationRepository(),
        dashboardRepository: MockDashboardRepository(
          employeeRepository: MockEmployeeRepository(delay: Duration.zero),
          delay: Duration.zero,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    addTearDown(auth.events.close);

    expect(find.text('invited@example.test'), findsOneWidget);
    await tester.tap(find.byKey(const Key('resend-verification')));
    await tester.pump();
    expect(auth.resendCalls, 1);
    await tester.tap(
      find.byKey(const Key('resend-verification')),
      warnIfMissed: false,
    );
    expect(auth.resendCalls, 1);
    auth.pendingResend!.complete();
    await tester.pumpAndSettle();
    ToastService.dismissAll();

    await tester.tap(find.byKey(const Key('verification-back-to-login')));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Shiftly'), findsOneWidget);
    expect(auth.signOutCalls, 1);
  });

  test('verification resend preserves a safe failure', () async {
    const failure = Failure(
      message: 'Too many attempts. Please wait and try again.',
      kind: FailureKind.validation,
    );
    final auth = _RegistrationAuth()
      ..resendError = const AuthenticationException(failure);
    final setup = _coordinator(auth);
    addTearDown(setup.coordinator.close);
    addTearDown(auth.events.close);
    await setup.coordinator.initialize();
    await setup.coordinator.signUp(
      email: 'person@example.test',
      password: 'not-recorded',
    );

    expect(await setup.coordinator.resendVerificationEmail(), isFalse);
    expect(auth.resendCalls, 1);
    expect(
      setup.coordinator.state.status,
      SessionStatus.emailVerificationRequired,
    );
    expect(setup.coordinator.state.failure?.message, failure.message);
  });

  testWidgets('registration shows safe provider failures', (tester) async {
    final auth = _RegistrationAuth()
      ..signUpError = const AuthenticationException(
        Failure(
          message: 'An account with this email already exists. Try signing in.',
          kind: FailureKind.validation,
        ),
      );
    final setup = _coordinator(auth);
    await setup.coordinator.initialize();
    await tester.pumpWidget(
      ShiftlyApp(
        sessionCoordinator: setup.coordinator,
        notificationRepository: MockNotificationRepository(),
        dashboardRepository: MockDashboardRepository(
          employeeRepository: MockEmployeeRepository(delay: Duration.zero),
          delay: Duration.zero,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    addTearDown(auth.events.close);
    await tester.tap(find.byKey(const Key('login-create-account')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('register-email')),
      'person@example.test',
    );
    await tester.enterText(
      find.byKey(const Key('register-password')),
      'strong-password',
    );
    await tester.enterText(
      find.byKey(const Key('register-confirm-password')),
      'strong-password',
    );
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.pump();

    expect(
      find.text('An account with this email already exists. Try signing in.'),
      findsOneWidget,
    );
    ToastService.dismissAll();
  });
}
