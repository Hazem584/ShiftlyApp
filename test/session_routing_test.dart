import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/app.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/storage/active_workspace_storage.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';
import 'package:shiftly/features/auth/domain/entities/auth_session.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_repository.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';

class _RoutingAuth implements AuthenticationService {
  _RoutingAuth() : session = const AuthSession(accessToken: 'token');

  AuthSession? session;
  final events = StreamController<AuthenticationEvent>.broadcast();

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
  }) async => AuthenticationResult(session: session);
  @override
  Future<AuthenticationResult> signUp({
    required String email,
    required String password,
  }) async => AuthenticationResult(session: session);
}

class _RoutingRepository implements AuthenticationRepository {
  _RoutingRepository(this.user);
  final CurrentUser user;

  @override
  Future<void> bootstrapProfile({String? fullName, String? phone}) async {}
  @override
  Future<CurrentUser> loadCurrentUser() async => user;
}

CurrentUser _routingUser(WorkspaceRole role) => CurrentUser(
  id: 'profile',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  memberships: [
    WorkspaceMembership(
      role: role,
      status: MembershipStatus.active,
      workspace: const Workspace(
        id: 'workspace',
        name: 'Cairo Operations',
        code: 'CAIRO',
        timezone: 'Africa/Cairo',
      ),
    ),
  ],
);

Future<_RoutingAuth> _pumpRole(WidgetTester tester, WorkspaceRole role) async {
  final auth = _RoutingAuth();
  final coordinator = SessionCoordinator(
    auth,
    _RoutingRepository(_routingUser(role)),
    MemoryActiveWorkspaceStorage(),
  );
  await coordinator.initialize();
  await tester.pumpWidget(ShiftlyApp(sessionCoordinator: coordinator));
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  addTearDown(auth.events.close);
  return auth;
}

void main() {
  testWidgets('backend manager role opens the manager shell', (tester) async {
    await _pumpRole(tester, WorkspaceRole.manager);
    expect(find.byKey(const Key('manager-bottom-navigation')), findsOneWidget);
    expect(find.textContaining('Good morning'), findsOneWidget);
  });

  testWidgets('backend employee role opens only the employee shell', (
    tester,
  ) async {
    await _pumpRole(tester, WorkspaceRole.employee);
    expect(find.text('Employee workspace'), findsOneWidget);
    expect(find.byKey(const Key('manager-bottom-navigation')), findsNothing);
  });

  testWidgets('logout replaces protected manager navigation with login', (
    tester,
  ) async {
    await _pumpRole(tester, WorkspaceRole.manager);
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('manager-logout')),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('profile-content')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const Key('manager-logout')));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Shiftly'), findsOneWidget);
    expect(find.byKey(const Key('manager-bottom-navigation')), findsNothing);
  });
}
