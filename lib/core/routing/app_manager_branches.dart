import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/features/chat/presentation/screens/chat_groups_screen.dart';
import 'package:shiftly/features/chat/presentation/screens/chat_screen.dart';
import 'package:shiftly/features/employees/presentation/screens/add_employee_screen.dart';
import 'package:shiftly/features/employees/presentation/screens/employee_details_screen.dart';
import 'package:shiftly/features/profile/presentation/screens/profile_screen.dart';
import 'package:shiftly/features/reports/presentation/attendance_reports_screen.dart';
import 'package:shiftly/features/shell/presentation/screens/team_hub_screen.dart';
import 'package:shiftly/features/shell/presentation/screens/work_hub_screen.dart';

List<StatefulShellBranch> buildManagerTeamAndChatBranches(
  GlobalKey<NavigatorState> rootNavigatorKey,
  Future<void> Function()? onLogout,
) => [
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/employees',
        builder: (_, state) => TeamHubScreen(
          section: state.uri.queryParameters['tab'] ?? 'employees',
        ),
        routes: [
          GoRoute(path: 'add', builder: (_, _) => const AddEmployeeScreen()),
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
        builder: (_, state) =>
            WorkHubScreen(section: state.uri.queryParameters['tab'] ?? 'hub'),
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
        builder: (_, _) => ProfileScreen(onLogout: onLogout),
      ),
    ],
  ),
];
