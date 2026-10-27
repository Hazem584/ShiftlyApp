import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/localization/language_selector.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/theme/theme_selector.dart';
import 'package:shiftly/core/widgets/workspace_content_frame.dart';
import 'package:shiftly/features/attendance/presentation/screens/employee_attendance_screen.dart';
import 'package:shiftly/features/auth/presentation/widgets/workspace_switcher.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/chat/presentation/screens/chat_groups_screen.dart';
import 'package:shiftly/features/dashboard/presentation/screens/employee_dashboard_screen.dart';
import 'package:shiftly/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:shiftly/features/points/presentation/screens/my_performance_screen.dart';
import 'package:shiftly/features/shell/presentation/widgets/workspace_navigation_rail.dart';

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
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 840 && size.height >= 600;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Employee workspace')),
        actions: [
          const LanguageSelector(),
          const ThemeSelector(),
          const NotificationBell(),
          IconButton(
            key: const Key('employee-devices'),
            tooltip: context.tr('Devices and sessions'),
            onPressed: () => context.push('/devices'),
            icon: const Icon(Icons.devices),
          ),
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
            tooltip: context.tr('Switch workspace'),
            icon: const Icon(Icons.business_outlined),
          ),
          IconButton(
            key: const Key('employee-logout'),
            onPressed: context.read<SessionCoordinator>().signOut,
            tooltip: context.tr('Sign out'),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
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
                      child: const ChatGroupsScreen(embedded: true),
                    ),
                    TickerMode(
                      enabled: _selectedIndex == 3,
                      child: const MyPerformanceScreen(),
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
          : BlocBuilder<ChatGroupsCubit, ChatGroupsState>(
              buildWhen: (before, after) =>
                  before.unreadCount != after.unreadCount,
              builder: (context, chat) => Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: NavigationBar(
                    key: const Key('employee-bottom-navigation'),
                    selectedIndex: _selectedIndex,
                    labelBehavior:
                        NavigationDestinationLabelBehavior.alwaysShow,
                    onDestinationSelected: (index) =>
                        setState(() => _selectedIndex = index),
                    destinations: [
                      NavigationDestination(
                        icon: const Icon(Icons.home_outlined),
                        selectedIcon: const Icon(Icons.home_rounded),
                        label: context.tr('Overview'),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.calendar_month_outlined),
                        selectedIcon: const Icon(Icons.calendar_month_rounded),
                        label: context.tr('My Shifts'),
                      ),
                      NavigationDestination(
                        icon: Badge(
                          isLabelVisible: chat.unreadCount > 0,
                          label: Text(
                            chat.unreadCount > 99
                                ? '99+'
                                : context.tr('{value1}', {
                                    'value1': (chat.unreadCount).toString(),
                                  }),
                          ),
                          child: const Icon(Icons.chat_bubble_outline_rounded),
                        ),
                        selectedIcon: Badge(
                          isLabelVisible: chat.unreadCount > 0,
                          label: Text(
                            chat.unreadCount > 99
                                ? '99+'
                                : context.tr('{value1}', {
                                    'value1': (chat.unreadCount).toString(),
                                  }),
                          ),
                          child: const Icon(Icons.chat_bubble_rounded),
                        ),
                        label: context.tr('Chat'),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.auto_graph_outlined),
                        selectedIcon: const Icon(Icons.auto_graph_rounded),
                        label: context.tr('Performance'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
