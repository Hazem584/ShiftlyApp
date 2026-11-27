import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/routing/app_manager_branches.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/chat/presentation/screens/chat_screen.dart';
import 'package:shiftly/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:shiftly/features/fixed_shifts/presentation/screens/shift_templates_screen.dart';
import 'package:shiftly/features/shell/presentation/screens/employee_shell_screen.dart';
import 'package:shiftly/features/shell/presentation/screens/shell_screen.dart';

GoRoute buildEmployeeShellRoute() => GoRoute(
  path: '/employee',
  builder: (_, state) => EmployeeShellScreen(
    initialAttendanceTab: switch (state.uri.queryParameters['tab']) {
      'leave' => 1,
      'calendar' => 2,
      'history' => 3,
      _ => 0,
    },
    initialTab: switch (state.uri.queryParameters['tab']) {
      'shifts' || 'attendance' || 'leave' || 'calendar' || 'history' => 1,
      'tasks' => 2,
      'chat' => 3,
      'profile' => 4,
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
);

StatefulShellRoute buildManagerShellRoute(
  GlobalKey<NavigatorState> rootNavigatorKey,
  SessionCoordinator? sessionCoordinator,
) => StatefulShellRoute.indexedStack(
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
    ...buildManagerTeamAndChatBranches(
      rootNavigatorKey,
      sessionCoordinator?.signOut,
    ),
  ],
);
