import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/routing/route_not_found_screen.dart';
import 'package:shiftly/features/attendance/presentation/attendance_screen.dart';
import 'package:shiftly/features/dashboard/presentation/dashboard_screen.dart';
import 'package:shiftly/features/employees/presentation/add_employee_screen.dart';
import 'package:shiftly/features/employees/presentation/employee_details_screen.dart';
import 'package:shiftly/features/employees/presentation/employees_screen.dart';
import 'package:shiftly/features/profile/presentation/profile_screen.dart';
import 'package:shiftly/features/shell/presentation/shell_screen.dart';

GoRouter createAppRouter() => GoRouter(
  initialLocation: '/dashboard',
  errorBuilder: (context, state) =>
      RouteNotFoundScreen(routeName: state.uri.path),
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => ShellScreen(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, _) => const DashboardScreen(),
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
                initialTab: state.uri.queryParameters['tab'] == 'leaveRequests'
                    ? 1
                    : 0,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
          ],
        ),
      ],
    ),
  ],
);
