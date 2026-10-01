import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/attendance/presentation/screens/employee_attendance_screen.dart';
import 'package:shiftly/features/dashboard/presentation/screens/employee_dashboard_screen.dart';
import 'package:shiftly/features/shifts/presentation/screens/employee_shifts_screen.dart';
import 'package:shiftly/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:shiftly/features/auth/presentation/widgets/workspace_switcher.dart';
import 'package:shiftly/features/chat/presentation/screens/chat_groups_screen.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';

class EmployeeShellScreen extends StatefulWidget {
  const EmployeeShellScreen({this.initialTab = 0, super.key});

  final int initialTab;

  @override
  State<EmployeeShellScreen> createState() => _EmployeeShellScreenState();
}

class _EmployeeShellScreenState extends State<EmployeeShellScreen> {
  late int _selectedIndex;
  bool _switchingWorkspace = false;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee workspace'),
        actions: [
          const NotificationBell(),
          IconButton(
            key: const Key('employee-switch-workspace'),
            onPressed: _switchingWorkspace
                ? null
                : () => showWorkspaceSwitcher(
                    context,
                    onSwitchingChanged: (switching) {
                      if (mounted) {
                        setState(() => _switchingWorkspace = switching);
                      }
                    },
                  ),
            tooltip: 'Switch workspace',
            icon: const Icon(Icons.business_outlined),
          ),
          IconButton(
            key: const Key('employee-logout'),
            onPressed: context.read<SessionCoordinator>().signOut,
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: const [
            EmployeeDashboardScreen(),
            EmployeeShiftsScreen(),
            EmployeeAttendanceScreen(),
            ChatGroupsScreen(embedded: true),
          ],
        ),
      ),
      bottomNavigationBar: BlocBuilder<ChatGroupsCubit, ChatGroupsState>(
        buildWhen: (before, after) => before.unreadCount != after.unreadCount,
        builder: (context, chat) => NavigationBar(
          key: const Key('employee-bottom-navigation'),
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Overview',
            ),
            const NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded),
              label: 'My Shifts',
            ),
            const NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              selectedIcon: Icon(Icons.fact_check_rounded),
              label: 'Attendance',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: chat.unreadCount > 0,
                label: Text(
                  chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                ),
                child: const Icon(Icons.chat_bubble_outline_rounded),
              ),
              selectedIcon: Badge(
                isLabelVisible: chat.unreadCount > 0,
                label: Text(
                  chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                ),
                child: const Icon(Icons.chat_bubble_rounded),
              ),
              label: 'Chat',
            ),
          ],
        ),
      ),
    );
  }
}
