import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/routing/route_not_found_screen.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/login_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/register_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/profile_setup_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/session_status_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/workspace_selection_screen.dart';
import 'package:shiftly/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:shiftly/features/employees/presentation/screens/add_employee_screen.dart';
import 'package:shiftly/features/employees/presentation/screens/employee_details_screen.dart';
import 'package:shiftly/features/employees/presentation/screens/employees_screen.dart';
import 'package:shiftly/features/profile/presentation/screens/profile_screen.dart';
import 'package:shiftly/features/shifts/presentation/screens/manager_shifts_screen.dart';
import 'package:shiftly/features/shell/presentation/screens/employee_shell_screen.dart';
import 'package:shiftly/features/shell/presentation/screens/shell_screen.dart';

GoRouter createAppRouter({
  SessionCoordinator? sessionCoordinator,
  Listenable? refreshListenable,
}) => GoRouter(
  initialLocation: sessionCoordinator == null ? '/dashboard' : '/session',
  refreshListenable: refreshListenable,
  redirect: sessionCoordinator == null
      ? null
      : (context, state) => _redirect(sessionCoordinator, state),
  errorBuilder: (context, state) =>
      RouteNotFoundScreen(routeName: state.uri.path),
  routes: [
    GoRoute(
      path: '/session',
      builder: (_, _) => const SessionStatusScreen.loading(),
    ),
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
    GoRoute(
      path: '/verify-email',
      builder: (_, _) => const EmailVerificationScreen(),
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (_, _) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: '/workspaces',
      builder: (_, _) => const WorkspaceSelectionScreen(),
    ),
    GoRoute(
      path: '/offline',
      builder: (_, _) => const SessionStatusScreen.offline(),
    ),
    GoRoute(
      path: '/session-error',
      builder: (_, _) => const SessionStatusScreen.failure(),
    ),
    GoRoute(
      path: '/employee',
      builder: (_, state) => EmployeeShellScreen(
        key: ValueKey(state.uri.queryParameters['tab']),
        initialTab: switch (state.uri.queryParameters['tab']) {
          'shifts' => 1,
          'attendance' || 'leave' => 2,
          _ => 0,
        },
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => ShellScreen(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, _) => const DashboardScreen(),
              routes: [
                GoRoute(
                  path: 'shifts',
                  builder: (_, _) => ManagerShiftsScreen(
                    timezone:
                        sessionCoordinator
                            ?.state
                            .activeMembership
                            ?.workspace
                            .timezone ??
                        'Etc/UTC',
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/employees',
              builder: (_, _) => const EmployeesScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (_, _) => const AddEmployeeScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (_, state) => EmployeeDetailsScreen(
                    employeeId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/attendance',
              builder: (_, state) => AttendanceScreen(
                key: ValueKey(state.uri.queryParameters['tab']),
                timezone:
                    sessionCoordinator
                        ?.state
                        .activeMembership
                        ?.workspace
                        .timezone ??
                    'Etc/UTC',
                initialTab: state.uri.queryParameters['tab'] == 'leaveRequests'
                    ? 1
                    : 0,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (_, _) =>
                  ProfileScreen(onLogout: sessionCoordinator?.signOut),
            ),
          ],
        ),
      ],
    ),
  ],
);

String? _redirect(SessionCoordinator coordinator, GoRouterState route) {
  final status = coordinator.state.status;
  final location = route.matchedLocation;
  return switch (status) {
    SessionStatus.initializing || SessionStatus.loadingCurrentUser =>
      location == '/session' ? null : '/session',
    SessionStatus.unauthenticated || SessionStatus.sessionExpired =>
      location == '/login' || location == '/register' ? null : '/login',
    SessionStatus.authenticating => location == '/login' ? null : '/login',
    SessionStatus.registering => location == '/register' ? null : '/register',
    SessionStatus.emailVerificationRequired =>
      location == '/verify-email' ? null : '/verify-email',
    SessionStatus.profileSetupRequired =>
      location == '/profile-setup' ? null : '/profile-setup',
    SessionStatus.workspaceSelectionRequired =>
      location == '/workspaces' ? null : '/workspaces',
    SessionStatus.offlineWithSession =>
      location == '/offline' ? null : '/offline',
    SessionStatus.failure =>
      location == '/login' ||
              location == '/register' ||
              location == '/session-error'
          ? null
          : '/session-error',
    SessionStatus.authenticatedManager => _managerRedirect(location),
    SessionStatus.authenticatedEmployee =>
      location == '/employee' ? null : '/employee',
  };
}

String? _managerRedirect(String location) {
  const public = {
    '/session',
    '/login',
    '/register',
    '/verify-email',
    '/profile-setup',
    '/workspaces',
    '/offline',
    '/session-error',
    '/employee',
  };
  return public.contains(location) ? '/dashboard' : null;
}
