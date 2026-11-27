import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/attendance/presentation/screens/employee_attendance_screen.dart';
import 'package:shiftly/features/chat/presentation/screens/chat_groups_screen.dart';
import 'package:shiftly/features/dashboard/presentation/screens/employee_dashboard_screen.dart';
import 'package:shiftly/features/profile/presentation/screens/profile_screen.dart';
import 'package:shiftly/features/tasks/presentation/tasks_screen.dart';

List<Widget> buildEmployeeShellTabs(
  BuildContext context, {
  required int selectedIndex,
  required int initialAttendanceTab,
}) => [
  TickerMode(
    enabled: selectedIndex == 0,
    child: const EmployeeDashboardScreen(),
  ),
  TickerMode(
    enabled: selectedIndex == 1,
    child: EmployeeAttendanceScreen(initialTab: initialAttendanceTab),
  ),
  TickerMode(enabled: selectedIndex == 2, child: const TasksScreen()),
  TickerMode(
    enabled: selectedIndex == 3,
    child: const ChatGroupsScreen(embedded: true),
  ),
  TickerMode(
    enabled: selectedIndex == 4,
    child: ProfileScreen(onLogout: context.read<SessionCoordinator>().signOut),
  ),
];
