import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';

class WorkspaceNavigationRail extends StatelessWidget {
  const WorkspaceNavigationRail({
    required this.selectedIndex,
    required this.onSelected,
    this.employee = false,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool employee;

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<ChatGroupsCubit, ChatGroupsState>(
    buildWhen: (before, after) => before.unreadCount != after.unreadCount,
    builder: (context, chat) => SafeArea(
      child: NavigationRail(
        key: Key(
          employee ? 'employee-navigation-rail' : 'manager-navigation-rail',
        ),
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.selected,
        labelType: NavigationRailLabelType.all,
        leading: const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Icon(Icons.layers_rounded, color: AppColors.orange, size: 32),
        ),
        destinations: [
          NavigationRailDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: Text(employee ? 'Overview' : 'Dashboard'),
          ),
          NavigationRailDestination(
            icon: Icon(
              employee ? Icons.calendar_month_outlined : Icons.groups_outlined,
            ),
            selectedIcon: Icon(
              employee ? Icons.calendar_month_rounded : Icons.groups_rounded,
            ),
            label: Text(employee ? 'My Shifts' : 'Employees'),
          ),
          const NavigationRailDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check_rounded),
            label: Text('Attendance'),
          ),
          NavigationRailDestination(
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
            label: const Text('Chat'),
          ),
          NavigationRailDestination(
            icon: Icon(
              employee
                  ? Icons.auto_graph_outlined
                  : Icons.person_outline_rounded,
            ),
            selectedIcon: Icon(
              employee ? Icons.auto_graph_rounded : Icons.person_rounded,
            ),
            label: Text(employee ? 'Performance' : 'Profile'),
          ),
        ],
      ),
    ),
  );
}
