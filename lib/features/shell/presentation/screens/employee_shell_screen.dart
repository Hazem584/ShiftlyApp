import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/widgets/workspace_content_frame.dart';
import 'package:shiftly/features/attendance/presentation/screens/employee_attendance_screen.dart';
import 'package:shiftly/features/chat/presentation/screens/chat_groups_screen.dart';
import 'package:shiftly/features/dashboard/presentation/screens/employee_dashboard_screen.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_bottom_navigation.dart';
import 'package:shiftly/features/profile/presentation/screens/profile_screen.dart';
import 'package:shiftly/features/shell/presentation/widgets/workspace_navigation_rail.dart';
import 'package:shiftly/features/tasks/presentation/tasks_screen.dart';

class EmployeeShellScreen extends StatefulWidget {
  const EmployeeShellScreen({
    this.initialTab = 0,
    this.initialAttendanceTab = 0,
    super.key,
  });

  final int initialTab;
  final int initialAttendanceTab;

  @override
  State<EmployeeShellScreen> createState() => _EmployeeShellScreenState();
}

class _EmployeeShellScreenState extends State<EmployeeShellScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
  }

  @override
  void didUpdateWidget(covariant EmployeeShellScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _selectedIndex = widget.initialTab;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 840 && size.height >= 600;
    return Scaffold(
      body: Row(
        children: [
          if (wide) ...[
            WorkspaceNavigationRail(
              extended: size.width >= 1200,
              employee: true,
              selectedIndex: _selectedIndex,
              onSelected: (index) => setState(() => _selectedIndex = index),
            ),
            const VerticalDivider(width: 1),
          ],
          Expanded(
            child: WorkspaceContentFrame(
              framed: wide,
              child: SafeArea(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    TickerMode(
                      enabled: _selectedIndex == 0,
                      child: const EmployeeDashboardScreen(),
                    ),
                    TickerMode(
                      enabled: _selectedIndex == 1,
                      child: EmployeeAttendanceScreen(
                        initialTab: widget.initialAttendanceTab,
                      ),
                    ),
                    TickerMode(
                      enabled: _selectedIndex == 2,
                      child: const TasksScreen(),
                    ),
                    TickerMode(
                      enabled: _selectedIndex == 3,
                      child: const ChatGroupsScreen(embedded: true),
                    ),
                    TickerMode(
                      enabled: _selectedIndex == 4,
                      child: ProfileScreen(
                        onLogout: context.read<SessionCoordinator>().signOut,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : EmployeeBottomNavigation(
              selectedIndex: _selectedIndex,
              onSelected: (index) => setState(() => _selectedIndex = index),
            ),
    );
  }
}
