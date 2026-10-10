import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/storage/active_workspace_storage.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/auth/domain/entities/auth_session.dart';
import 'package:shiftly/features/auth/domain/entities/authentication_exception.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_repository.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';
import 'package:shiftly/features/auth/presentation/screens/login_screen.dart';

class _PendingAuth implements AuthenticationService {
  final completer = Completer<AuthenticationResult>();
  final events = StreamController<AuthenticationEvent>.broadcast();
  Object? error;
  int calls = 0;

  @override
  Stream<AuthenticationEvent> get authStateChanges => events.stream;
  @override
  AuthSession? get currentSession => null;
  @override
  Future<AuthSession?> refreshSession() async => null;
  @override
  Future<AuthenticationResult> signIn({
    required String email,
    required String password,
  }) {
    calls++;
    if (error case final Object value) return Future.error(value);
    return completer.future;
  }

  @override
  Future<AuthenticationResult> signUp({
    required String email,
    required String password,
  }) => completer.future;
  @override
  Future<void> resendSignUpVerification({required String email}) async {}
  @override
  Future<void> signOut() async {}
}

class _UnusedRepository implements AuthenticationRepository {
  @override
  Future<void> bootstrapProfile({String? fullName, String? phone}) async {}
  @override
  Future<CurrentUser> loadCurrentUser() => throw UnimplementedError();
}

Future<SessionCoordinator> _pump(
  WidgetTester tester,
  _PendingAuth auth, {
  Locale? locale,
}) async {
  final coordinator = SessionCoordinator(
    auth,
    _UnusedRepository(),
    MemoryActiveWorkspaceStorage(),
  );
  await coordinator.initialize();
  await tester.pumpWidget(
    BlocProvider.value(
      value: coordinator,
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.lightTheme(),
        home: const LoginScreen(),
      ),
    ),
  );
  addTearDown(coordinator.close);
  addTearDown(auth.events.close);
  return coordinator;
}

Future<void> _fillAndSubmit(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('login-email')),
    'person@example.com',
  );
  await tester.enterText(find.byKey(const Key('login-password')), 'password');
  await tester.tap(find.byKey(const Key('login-submit')));
  await tester.pump();
}

void main() {
  testWidgets(
    'Arabic login validates inputs, keeps credentials LTR and translates authentication failures',
    (tester) async {
      final auth = _PendingAuth()
        ..error = const AuthenticationException(
          Failure(message: 'The email or password is incorrect.'),
        );
      await _pump(tester, auth, locale: const Locale('ar'));
      expect(find.text('أهلًا بك في Shiftly'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const Key('login-email')),
                matching: find.byType(TextField),
              ),
            )
            .textDirection,
        TextDirection.ltr,
      );
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pump();
      expect(find.text('أدخل بريدًا إلكترونيًا صحيحًا'), findsOneWidget);
      expect(find.text('أدخل كلمة المرور'), findsOneWidget);
      expect(auth.calls, 0);
      await _fillAndSubmit(tester);
      await tester.pump();
      expect(
        find.text('البريد الإلكتروني أو كلمة المرور غير صحيحة.'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 4));
    },
  );
  testWidgets('login shows loading and prevents duplicate submissions', (
    tester,
  ) async {
    final auth = _PendingAuth();
    await _pump(tester, auth);
    await _fillAndSubmit(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('login-submit')),
    );
    expect(button.onPressed, isNull);
    await tester.tap(
      find.byKey(const Key('login-submit')),
      warnIfMissed: false,
    );
    expect(auth.calls, 1);
    auth.completer.complete(
      const AuthenticationResult(
        session: null,
        emailVerificationRequired: true,
      ),
    );
    await tester.pump();
  });

  testWidgets('login displays a safe authentication failure', (tester) async {
    final auth = _PendingAuth()
      ..error = const AuthenticationException(
        Failure(message: 'The email or password is incorrect.'),
      );
    await _pump(tester, auth);
    await _fillAndSubmit(tester);
    await tester.pump();
    expect(find.text('The email or password is incorrect.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });
}
