import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/routing/route_not_found_screen.dart';
import 'package:shiftly/core/routing/session_route_intent.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/login_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/profile_setup_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/register_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/session_status_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/workspace_selection_screen.dart';
import 'package:shiftly/features/chat/presentation/screens/chat_groups_screen.dart';
import 'package:shiftly/features/chat/presentation/screens/chat_screen.dart';
import 'package:shiftly/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:shiftly/features/device_sessions/presentation/device_sessions_screen.dart';
import 'package:shiftly/features/employees/presentation/screens/add_employee_screen.dart';
import 'package:shiftly/features/employees/presentation/screens/employee_details_screen.dart';
import 'package:shiftly/features/fixed_shifts/presentation/screens/shift_templates_screen.dart';
import 'package:shiftly/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:shiftly/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:shiftly/features/profile/presentation/screens/profile_screen.dart';
import 'package:shiftly/features/reports/presentation/attendance_reports_screen.dart';
import 'package:shiftly/features/shell/presentation/screens/employee_shell_screen.dart';
import 'package:shiftly/features/shell/presentation/screens/shell_screen.dart';
import 'package:shiftly/features/shell/presentation/screens/team_hub_screen.dart';
import 'package:shiftly/features/shell/presentation/screens/work_hub_screen.dart';
import 'package:shiftly/features/tasks/presentation/tasks_screen.dart';
import 'package:shiftly/features/team_work/presentation/team_work_screen.dart';

GoRouter createAppRouter({
  SessionCoordinator? sessionCoordinator,
  OnboardingCubit? onboarding,
  Listenable? refreshListenable,
}) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final routeIntent = SessionRouteIntent();
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: sessionCoordinator == null ? '/dashboard' : '/session',
    refreshListenable: refreshListenable,
    redirect: sessionCoordinator == null
        ? null
        : (context, state) {
            routeIntent.remember(state.uri, sessionCoordinator.state.status);
            final redirect = _redirect(sessionCoordinator, state, onboarding);
            return redirect == null
                ? null
                : routeIntent.takeFor(sessionCoordinator.state.status) ??
                      redirect;
          },
    errorBuilder: (context, state) =>
        RouteNotFoundScreen(routeName: state.uri.path),
    routes: [
      GoRoute(
        path: '/attendance',
        redirect: (_, state) => state.uri.queryParameters['tab'] == 'calendar'
            ? '/employees?tab=calendar'
            : state.uri.queryParameters['tab'] == 'leaveRequests'
            ? '/employees?tab=leaveRequests'
            : '/employees?tab=attendance',
      ),
      GoRoute(
        path: '/attendance/reports',
        redirect: (_, _) => '/employees?tab=reports',
      ),
      GoRoute(
        path: '/devices',
        builder: (_, _) => DeviceSessionsScreen(
          onCurrentSessionRevoked: () async {
            await sessionCoordinator?.signOut();
          },
        ),
      ),
      GoRoute(
        path: '/tasks',
        builder: (_, state) =>
            TasksScreen(taskId: state.uri.queryParameters['taskId']),
      ),
      GoRoute(
        path: '/team-work',
        builder: (_, state) => TeamWorkScreen(
          initialTab: state.uri.queryParameters['tab'] ?? 'announcements',
        ),
      ),

      GoRoute(
        path: '/session',
        builder: (_, _) => const SessionStatusScreen.loading(),
      ),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
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
          initialAttendanceTab: state.uri.queryParameters['tab'] == 'leave'
              ? 1
              : 0,
          initialTab: switch (state.uri.queryParameters['tab']) {
            'shifts' || 'attendance' || 'leave' => 1,
            'chat' => 2,
            'profile' => 3,
            _ => 0,
          },
        ),
        routes: [
          GoRoute(
            path: 'chat/:groupId',
            builder: (_, state) =>
                ChatScreen(groupId: state.pathParameters['groupId']!),
          ),
        ],
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
                    builder: (_, _) => ShiftTemplatesScreen(
                      workspaceName:
                          sessionCoordinator
                              ?.state
                              .activeMembership
                              ?.workspace
                              .name ??
                          'Current workspace',
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
                builder: (_, state) => TeamHubScreen(
                  section: state.uri.queryParameters['tab'] ?? 'employees',
                ),
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
                path: '/work',
                builder: (_, state) => WorkHubScreen(
                  section: state.uri.queryParameters['tab'] ?? 'tasks',
                ),
                routes: [
                  GoRoute(
                    path: 'reports',
                    builder: (_, _) => const AttendanceReportsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                builder: (_, _) => const ChatGroupsScreen(),
                routes: [
                  GoRoute(
                    path: ':groupId',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (_, state) =>
                        ChatScreen(groupId: state.pathParameters['groupId']!),
                  ),
                ],
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
}

String? _redirect(
  SessionCoordinator coordinator,
  GoRouterState route,
  OnboardingCubit? onboarding,
) {
  final status = coordinator.state.status;
  final location = route.matchedLocation;
  return switch (status) {
    SessionStatus.initializing || SessionStatus.loadingCurrentUser =>
      location == '/session' ? null : '/session',
    SessionStatus.unauthenticated => _signedOutRedirect(
      location,
      coordinator.state.failure?.kind == FailureKind.authentication
          ? null
          : onboarding,
    ),
    SessionStatus.sessionExpired =>
      location == '/login' || location == '/register' ? null : '/login',
    SessionStatus.authenticating => location == '/login' ? null : '/login',
    SessionStatus.registering => location == '/register' ? null : '/register',
    SessionStatus.emailVerificationRequired =>
      location == '/verify-email' ? null : '/verify-email',
    SessionStatus.profileSetupRequired =>
      location == '/profile-setup' || location == '/devices'
          ? null
          : '/profile-setup',
    SessionStatus.workspaceSelectionRequired =>
      location == '/workspaces' || location == '/devices'
          ? null
          : '/workspaces',
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
      location == '/devices' ||
              location == '/tasks' ||
              location == '/team-work' ||
              location == '/workspaces' ||
              location == '/employee' ||
              location.startsWith('/employee/chat/')
          ? null
          : '/employee',
  };
}

String? _managerRedirect(String location) {
  if (location.startsWith('/employee/')) return '/dashboard';
  const public = {
    '/session',
    '/onboarding',
    '/login',
    '/register',
    '/verify-email',
    '/profile-setup',
    '/offline',
    '/session-error',
    '/employee',
  };
  return public.contains(location) ? '/dashboard' : null;
}

String? _signedOutRedirect(String location, OnboardingCubit? onboarding) {
  if (onboarding != null &&
      !onboarding.bypassed &&
      !onboarding.state.completed) {
    final target = onboarding.state.loading ? '/session' : '/onboarding';
    return location == target ? null : target;
  }
  return location == '/login' || location == '/register' ? null : '/login';
}
