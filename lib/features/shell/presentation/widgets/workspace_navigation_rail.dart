import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/shell/presentation/widgets/workspace_brand.dart';
import 'package:shiftly/features/shell/presentation/widgets/workspace_navigation_destinations.dart';

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
  Widget build(BuildContext context) =>
      BlocBuilder<ChatGroupsCubit, ChatGroupsState>(
        buildWhen: (before, after) => before.unreadCount != after.unreadCount,
        builder: (context, chat) => SafeArea(
          child: NavigationRail(
            key: Key(
              employee ? 'employee-navigation-rail' : 'manager-navigation-rail',
            ),
            selectedIndex: selectedIndex,
            scrollable: true,
            onDestinationSelected: onSelected,
            backgroundColor: AppPalette.of(context).surface,
            indicatorColor: AppPalette.of(context).selected,
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
                        onPressed: () => context.push('/attendance/reports'),
                        icon: const Icon(Icons.bar_chart_rounded),
                        label: Text(context.tr('Attendance reports')),
                      ),
                    ),
                  )
                : null,
            destinations: buildWorkspaceRailDestinations(
              context,
              employee: employee,
              unreadCount: chat.unreadCount,
            ),
          ),
        ),
      );
}
