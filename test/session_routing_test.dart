import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/app.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/storage/active_workspace_storage.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';
import 'package:shiftly/features/auth/domain/entities/auth_session.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_repository.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';
import 'package:shiftly/features/invitations/data/invitation_repository.dart';
import 'package:shiftly/features/dashboard/data/mock_dashboard_repository.dart';
import 'package:shiftly/features/employees/data/mock_employee_repository.dart';
import 'package:shiftly/features/notifications/data/mock_notification_repository.dart';
import 'package:shiftly/features/workspaces/data/workspace_repository.dart';

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
  @override
  Future<void> resendSignUpVerification({required String email}) async {}
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
  id: '4f6c53d3-8518-44d8-813e-b915cc93d203',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  memberships: [
    WorkspaceMembership(
      id: '040e52de-05b9-46b8-80ca-e7df3ef7444b',
      role: role,
      status: MembershipStatus.active,
      workspace: const Workspace(
        id: 'c551356a-e456-4a3e-a49a-9dd0caa7e790',
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
  await tester.pumpWidget(
    ShiftlyApp.preview(
      sessionCoordinator: coordinator,
      notificationRepository: MockNotificationRepository(),
      dashboardRepository: MockDashboardRepository(
        employeeRepository: MockEmployeeRepository(delay: Duration.zero),
        delay: Duration.zero,
        timezone: 'Africa/Cairo',
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  addTearDown(auth.events.close);
  return auth;
}

Future<(_RoutingAuth, _AcceptingInvitations)> _pumpNoWorkspace(
  WidgetTester tester,
) async {
  final auth = _RoutingAuth();
  final invitations = _AcceptingInvitations();
  final coordinator = SessionCoordinator(
    auth,
    _RoutingRepository(
      CurrentUser(
        id: 'profile',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        memberships: const [],
      ),
    ),
    MemoryActiveWorkspaceStorage(),
  );
  await coordinator.initialize();
  await tester.pumpWidget(
    ShiftlyApp.preview(
      sessionCoordinator: coordinator,
      invitationRepository: invitations,
      notificationRepository: MockNotificationRepository(),
      dashboardRepository: MockDashboardRepository(
        employeeRepository: MockEmployeeRepository(delay: Duration.zero),
        delay: Duration.zero,
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(auth.events.close);
  return (auth, invitations);
}

void main() {
  testWidgets('backend manager role opens the manager shell', (tester) async {
    await _pumpRole(tester, WorkspaceRole.manager);
    expect(find.byKey(const Key('manager-bottom-navigation')), findsOneWidget);
    expect(find.textContaining('Good morning'), findsOneWidget);
    expect(find.byKey(const Key('notification-bell')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('notification-badge')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('backend employee role opens only the employee shell', (
    tester,
  ) async {
    await _pumpRole(tester, WorkspaceRole.employee);
    expect(find.text('Employee workspace'), findsOneWidget);
    expect(find.text('Hello, Preview employee'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Performance'), findsOneWidget);
    expect(find.byKey(const Key('manager-bottom-navigation')), findsNothing);
    expect(find.byKey(const Key('notification-bell')), findsOneWidget);
    expect(find.byKey(const Key('employee-switch-workspace')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('notification-badge')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Performance'));
    await tester.pumpAndSettle();
    expect(find.text('My Performance'), findsWidgets);

    await tester.tap(find.text('Overview'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('performance-thumbnail')));
    await tester.pumpAndSettle();
    expect(find.text('My Performance'), findsWidgets);

    final shellContext = tester.element(
      find.byKey(const Key('employee-bottom-navigation')),
    );
    GoRouter.of(shellContext).go('/employee?tab=performance');
    await tester.pumpAndSettle();
    expect(find.text('My Performance'), findsWidgets);
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

  testWidgets(
    'no-workspace onboarding offers creation and invitation acceptance',
    (tester) async {
      final (_, invitations) = await _pumpNoWorkspace(tester);
      expect(find.byKey(const Key('no-workspace-onboarding')), findsOneWidget);
      expect(find.byKey(const Key('create-workspace')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('invitation-token-field')),
        ' one-time-token ',
      );
      await tester.tap(find.byKey(const Key('accept-invitation')));
      await tester.pumpAndSettle();

      expect(invitations.acceptedToken, 'one-time-token');
      ToastService.dismissAll();
    },
  );
}

class _AcceptingInvitations implements InvitationRepository {
  String? acceptedToken;

  @override
  Future<WorkspaceRecord> acceptInvitation(String inviteToken) async {
    acceptedToken = inviteToken;
    return const WorkspaceRecord(
      id: 'accepted-workspace',
      name: 'Accepted workspace',
      code: 'ACCEPTED',
      timezone: 'Africa/Cairo',
      role: WorkspaceAccessRole.employee,
      status: WorkspaceAccessStatus.active,
    );
  }

  @override
  Future<WorkspaceInvitation> createInvitation({
    required String workspaceId,
    required String email,
    String? jobTitle,
  }) => throw UnimplementedError();

  @override
  Future<List<WorkspaceInvitation>> listMyInvitations() async => const [];

  @override
  Future<List<WorkspaceInvitation>> listWorkspaceInvitations({
    required String workspaceId,
    InvitationStatus? status,
  }) => throw UnimplementedError();
}
