import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/app.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/storage/active_workspace_storage.dart';
import 'package:shiftly/core/widgets/brand_logo.dart';
import 'package:shiftly/core/widgets/brand_session_loading.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';
import 'package:shiftly/features/auth/domain/entities/auth_session.dart';
import 'package:shiftly/features/dashboard/data/mock_dashboard_repository.dart';
import 'package:shiftly/features/employees/data/mock_employee_repository.dart';
import 'package:shiftly/features/onboarding/data/preferences_onboarding_storage.dart';
import 'package:shiftly/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:shiftly/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:shiftly/features/onboarding/presentation/widgets/onboarding_illustration.dart';

import 'support/onboarding_test_auth.dart';
import 'support/onboarding_test_repository.dart';
import 'support/onboarding_test_storage.dart';

CurrentUser _user({
  WorkspaceRole role = WorkspaceRole.employee,
  bool workspace = true,
}) => CurrentUser(
  id: 'onboarding-user',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  memberships: workspace
      ? [
          WorkspaceMembership(
            id: 'onboarding-membership',
            role: role,
            status: MembershipStatus.active,
            workspace: const Workspace(
              id: 'onboarding-workspace',
              name: 'Test workspace',
              code: 'TEST',
              timezone: 'Africa/Cairo',
            ),
          ),
        ]
      : [],
);

Future<SessionCoordinator> _pumpApp(
  WidgetTester tester,
  OnboardingTestStorage storage,
  OnboardingTestAuth auth, {
  CurrentUser? user,
  ApiException? failure,
}) async {
  final coordinator = SessionCoordinator(
    auth,
    OnboardingTestRepository(user ?? _user(), failure: failure),
    MemoryActiveWorkspaceStorage(),
  );
  await coordinator.initialize();
  await tester.pumpWidget(
    ShiftlyApp.preview(
      onboardingStorage: storage,
      sessionCoordinator: coordinator,
      employeeRepository: MockEmployeeRepository(delay: Duration.zero),
      dashboardRepository: MockDashboardRepository(
        employeeRepository: MockEmployeeRepository(delay: Duration.zero),
        delay: Duration.zero,
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(auth.events.close);
  return coordinator;
}

void main() {
  test(
    'versioned preference restores completion and preserves unrelated keys',
    () async {
      SharedPreferences.setMockInitialValues({
        'auth.test': 'token',
        'workspace.test': 'workspace',
      });
      final preferences = await SharedPreferences.getInstance();
      final storage = PreferencesOnboardingStorage(preferences);
      expect(await storage.readCompleted(), isFalse);
      await storage.complete();
      expect(
        await PreferencesOnboardingStorage(preferences).readCompleted(),
        isTrue,
      );
      expect(preferences.getString('auth.test'), 'token');
      expect(preferences.getString('workspace.test'), 'workspace');
      expect(preferences.getBool(PreferencesOnboardingStorage.key), isTrue);
    },
  );

  test(
    'completion is durable before success and duplicate calls share one write',
    () async {
      final storage = OnboardingTestStorage()..writeGate = Completer<void>();
      final cubit = OnboardingCubit(storage);
      addTearDown(cubit.close);
      await cubit.restore();
      final first = cubit.complete();
      await cubit.complete();
      expect(storage.writes, 1);
      expect(cubit.state.saving, isTrue);
      expect(cubit.state.completed, isFalse);
      storage.writeGate!.complete();
      await first;
      expect(cubit.state.completed, isTrue);
      expect(storage.completed, isTrue);
    },
  );

  test('persistence failure preserves page and allows retry', () async {
    final storage = OnboardingTestStorage()..failWrite = true;
    final cubit = OnboardingCubit(storage);
    addTearDown(cubit.close);
    await cubit.restore();
    cubit.showPage(2);
    await cubit.complete();
    expect(cubit.state.completed, isFalse);
    expect(cubit.state.error, contains('Could not save'));
    expect(cubit.state.page, 2);
    storage.failWrite = false;
    await cubit.complete();
    expect(cubit.state.completed, isTrue);
    expect(storage.writes, 2);
  });

  test(
    'failed preference restoration can be retried and cannot claim completion',
    () async {
      final storage = OnboardingTestStorage()..failRead = true;
      final cubit = OnboardingCubit(storage);
      addTearDown(cubit.close);
      await cubit.restore();
      expect(cubit.state.error, contains('Could not read'));
      expect(cubit.state.completed, isFalse);
      storage.failRead = false;
      await cubit.restore();
      expect(cubit.state.error, isNull);
      expect(cubit.state.loading, isFalse);
    },
  );

  testWidgets(
    'first signed-out launch waits for preferences then shows onboarding without login flash',
    (tester) async {
      final storage = OnboardingTestStorage()..readGate = Completer<bool>();
      final auth = OnboardingTestAuth();
      final coordinator = SessionCoordinator(
        auth,
        OnboardingTestRepository(_user()),
        MemoryActiveWorkspaceStorage(),
      );
      await coordinator.initialize();
      await tester.pumpWidget(
        ShiftlyApp.preview(
          onboardingStorage: storage,
          sessionCoordinator: coordinator,
          dashboardRepository: MockDashboardRepository(
            employeeRepository: MockEmployeeRepository(delay: Duration.zero),
            delay: Duration.zero,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Getting Shiftly ready'), findsOneWidget);
      expect(find.text('Sign in'), findsNothing);
      storage.readGate!.complete(false);
      await tester.pumpAndSettle();
      expect(find.text('Your shifts, clearly organized'), findsOneWidget);
      expect(find.text('Sign in'), findsNothing);
      addTearDown(auth.events.close);
    },
  );

  testWidgets(
    'returning signed-out launch restores completion and goes to login',
    (tester) async {
      await _pumpApp(
        tester,
        OnboardingTestStorage()..completed = true,
        OnboardingTestAuth(),
      );
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.text('Sign in'), findsWidgets);
    },
  );

  for (final skip in [true, false]) {
    testWidgets(
      '${skip ? 'Skip' : 'Get Started'} persists before login; Next advances all three pages',
      (tester) async {
        final storage = OnboardingTestStorage()..writeGate = Completer<void>();
        await _pumpApp(tester, storage, OnboardingTestAuth());
        if (!skip) {
          await tester.ensureVisible(find.text('Next'));
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
          expect(find.text('See your progress'), findsOneWidget);
          await tester.ensureVisible(find.text('Next'));
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
          expect(find.text('Stay connected'), findsOneWidget);
        }
        final button = find.text(skip ? 'Skip' : 'Get Started');
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pump();
        expect(find.byType(OnboardingScreen), findsOneWidget);
        expect(storage.completed, isFalse);
        expect(storage.writes, 1);
        expect(
          tester
              .widget<TextButton>(find.widgetWithText(TextButton, 'Skip'))
              .onPressed,
          isNull,
        );
        storage.writeGate!.complete();
        await tester.pumpAndSettle();
        expect(find.byType(OnboardingScreen), findsNothing);
        expect(find.text('Sign in'), findsWidgets);
        expect(storage.completed, isTrue);
      },
    );
  }

  testWidgets('failed Skip stays recoverable and successful retry navigates', (
    tester,
  ) async {
    final storage = OnboardingTestStorage()..failWrite = true;
    await _pumpApp(tester, storage, OnboardingTestAuth());
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not save'), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    storage.failWrite = false;
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsWidgets);
  });

  for (final role in [WorkspaceRole.employee, WorkspaceRole.manager]) {
    testWidgets(
      'validated $role session bypasses onboarding and logout preserves completion',
      (tester) async {
        final storage = OnboardingTestStorage()..completed = true;
        final auth = OnboardingTestAuth()
          ..session = const AuthSession(accessToken: 'token');
        final coordinator = await _pumpApp(
          tester,
          storage,
          auth,
          user: _user(role: role),
        );
        expect(coordinator.state.isAuthenticated, isTrue);
        expect(find.byType(OnboardingScreen), findsNothing);
        expect(
          find.byKey(
            Key(
              role == WorkspaceRole.employee
                  ? 'employee-bottom-navigation'
                  : 'manager-bottom-navigation',
            ),
          ),
          findsOneWidget,
        );
        await coordinator.signOut();
        await tester.pumpAndSettle();
        expect(storage.completed, isTrue);
        expect(storage.writes, 0);
        expect(find.text('Sign in'), findsWidgets);
      },
    );
  }

  testWidgets(
    'validated session bypasses incomplete preference even when its read is unavailable',
    (tester) async {
      final storage = OnboardingTestStorage()..failRead = true;
      final auth = OnboardingTestAuth()
        ..session = const AuthSession(accessToken: 'token');
      final coordinator = await _pumpApp(tester, storage, auth);
      expect(coordinator.state.isAuthenticated, isTrue);
      expect(find.byType(OnboardingScreen), findsNothing);
      await coordinator.signOut();
      await tester.pumpAndSettle();
      expect(find.text('Sign in'), findsWidgets);
    },
  );

  testWidgets(
    'session change while onboarding is visible routes through the existing coordinator',
    (tester) async {
      final storage = OnboardingTestStorage();
      final auth = OnboardingTestAuth();
      final coordinator = await _pumpApp(tester, storage, auth);
      expect(find.byType(OnboardingScreen), findsOneWidget);
      await coordinator.signIn(
        email: 'test@example.test',
        password: 'test-password',
      );
      await tester.pumpAndSettle();
      expect(coordinator.state.isAuthenticated, isTrue);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(storage.writes, 0);
    },
  );

  testWidgets(
    'workspace selection remains authoritative before incomplete onboarding',
    (tester) async {
      final auth = OnboardingTestAuth()
        ..session = const AuthSession(accessToken: 'token');
      final coordinator = await _pumpApp(
        tester,
        OnboardingTestStorage(),
        auth,
        user: _user(workspace: false),
      );
      expect(coordinator.state.isAuthenticated, isFalse);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byKey(const Key('no-workspace-onboarding')), findsOneWidget);
    },
  );

  testWidgets('profile setup and offline recovery remain authoritative', (
    tester,
  ) async {
    for (final failure in [
      const ApiException(
        message: 'Profile required',
        code: 'PROFILE_NOT_INITIALIZED',
        statusCode: 404,
      ),
      const ApiException(
        message: 'Connect and retry',
        kind: FailureKind.network,
      ),
    ]) {
      final auth = OnboardingTestAuth()
        ..session = const AuthSession(accessToken: 'token');
      await _pumpApp(tester, OnboardingTestStorage(), auth, failure: failure);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(
        find.text(
          failure.code == 'PROFILE_NOT_INITIALIZED'
              ? 'Complete your profile'
              : 'You are offline',
        ),
        findsWidgets,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets(
    'expired session returns to login instead of incomplete onboarding',
    (tester) async {
      final auth = OnboardingTestAuth()
        ..session = const AuthSession(accessToken: 'token');
      await _pumpApp(
        tester,
        OnboardingTestStorage(),
        auth,
        failure: const ApiException(
          message: 'Expired',
          statusCode: 401,
          kind: FailureKind.authentication,
        ),
      );
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.text('Sign in'), findsWidgets);
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      'all pages fit 320px at 2x text scale; logo and ${dark ? 'dark' : 'light'} presentation load',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final cubit = OnboardingCubit(OnboardingTestStorage());
        addTearDown(cubit.close);
        await cubit.restore();
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: const Size(320, 640),
                textScaler: const TextScaler.linear(2),
                platformBrightness: dark ? Brightness.dark : Brightness.light,
                disableAnimations: true,
              ),
              child: BlocProvider.value(
                value: cubit,
                child: const OnboardingScreen(),
              ),
            ),
          ),
        );
        for (var index = 0; index < 3; index++) {
          expect(find.byType(BrandLogo), findsOneWidget);
          final context = tester.element(find.byType(OnboardingIllustration));
          expect(
            Theme.of(context).brightness,
            dark ? Brightness.dark : Brightness.light,
          );
          // Content and buttons must remain reachable by scrolling at larger text sizes.
          final action = find.text(index == 2 ? 'Get Started' : 'Next');
          await tester.ensureVisible(action);
          expect(tester.takeException(), isNull);
          if (index < 2) {
            await tester.tap(action);
            await tester.pumpAndSettle();
          }
        }
        expect(find.text('Stay connected'), findsOneWidget);
        expect(
          tester
              .widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher).first)
              .duration,
          Duration.zero,
        );
      },
    );
  }

  testWidgets('session loading uses approved asset and accessible status', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: BrandSessionLoading()));
    await tester.pump();
    expect(find.byType(BrandLogo), findsOneWidget);
    expect(find.text('Getting Shiftly ready'), findsOneWidget);
    expect(
      (tester.widget<Image>(find.byType(Image)).image as AssetImage).assetName,
      BrandLogo.asset,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('session loading remains readable in dark appearance', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(platformBrightness: Brightness.dark),
          child: BrandSessionLoading(),
        ),
      ),
    );
    await tester.pump();
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      const Color(0xFF080414),
    );
    expect(
      tester.widget<Text>(find.text('Getting Shiftly ready')).style!.color,
      Colors.white,
    );
    expect(tester.takeException(), isNull);
  });
}
