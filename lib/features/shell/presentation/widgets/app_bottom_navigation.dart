import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/constants/app_strings.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/shell/presentation/widgets/navigation_destination_item.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _destinations = [
    (Icons.home_outlined, Icons.home_rounded, AppStrings.dashboard),
    (Icons.groups_outlined, Icons.groups_rounded, AppStrings.employees),
    (Icons.schedule_outlined, Icons.schedule_rounded, AppStrings.attendance),
    (Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Chat'),
    (Icons.person_outline_rounded, Icons.person_rounded, AppStrings.profile),
  ];

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ChatGroupsCubit, ChatGroupsState>(
        buildWhen: (before, after) => before.unreadCount != after.unreadCount,
        builder: (context, chat) => DecoratedBox(
          key: const Key('manager-bottom-navigation'),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: const Border(top: BorderSide(color: AppColors.borderColor)),
            boxShadow: AppShadows.soft,
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 52 + MediaQuery.textScalerOf(context).scale(11) * 1.8,
              child: Row(
                children: [
                  for (var index = 0; index < _destinations.length; index++)
                    NavigationDestinationItem(
                      icon: selectedIndex == index
                          ? _destinations[index].$2
                          : _destinations[index].$1,
                      label: _destinations[index].$3,
                      index: index,
                      selected: selectedIndex == index,
                      onTap: () => onDestinationSelected(index),
                      badgeCount: index == 3 ? chat.unreadCount : 0,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}
