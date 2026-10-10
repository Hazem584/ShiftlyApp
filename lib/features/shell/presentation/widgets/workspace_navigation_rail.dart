import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/shell/presentation/widgets/workspace_brand.dart';

class WorkspaceNavigationRail extends StatelessWidget {
  const WorkspaceNavigationRail({
    required this.selectedIndex,
    required this.onSelected,
    this.employee = false,
    this.extended = false,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool employee;
  final bool extended;

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
        scrollable: true,
        onDestinationSelected: onSelected,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.selected,
        extended: extended,
        minExtendedWidth: 240,
        labelType: extended
            ? NavigationRailLabelType.none
            : NavigationRailLabelType.all,
        leading: WorkspaceBrand(extended: extended, employee: employee),
        trailing: extended && !employee
            ? Padding(
                padding: const EdgeInsets.only(top: 24),
                child: SizedBox(
                  width: 200,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/attendance/reports'),
                    icon: const Icon(Icons.bar_chart_rounded),
                    label: Text(context.tr('Attendance reports')),
                  ),
                ),
              )
            : null,
        destinations: [
          NavigationRailDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: Text(context.tr(employee ? 'Overview' : 'Dashboard')),
          ),
          NavigationRailDestination(
            icon: Icon(
              employee ? Icons.calendar_month_outlined : Icons.groups_outlined,
            ),
            selectedIcon: Icon(
              employee ? Icons.calendar_month_rounded : Icons.groups_rounded,
            ),
            label: Text(context.tr(employee ? 'My Shifts' : 'Employees')),
          ),
          NavigationRailDestination(
            icon: const Icon(Icons.fact_check_outlined),
            selectedIcon: const Icon(Icons.fact_check_rounded),
            label: Text(context.tr('Attendance')),
          ),
          NavigationRailDestination(
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
            label: Text(context.tr('Chat')),
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
            label: Text(context.tr(employee ? 'Performance' : 'Profile')),
          ),
        ],
      ),
    ),
  );
}
