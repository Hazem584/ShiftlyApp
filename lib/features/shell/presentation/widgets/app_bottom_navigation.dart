import 'package:flutter/material.dart';
import 'package:shiftly/core/constants/app_strings.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _destinations = [
    (Icons.home_rounded, AppStrings.dashboard),
    (Icons.groups_rounded, AppStrings.employees),
    (Icons.schedule_rounded, AppStrings.attendance),
    (Icons.chat_bubble_rounded, 'Chat'),
    (Icons.person_rounded, AppStrings.profile),
  ];

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ChatGroupsCubit, ChatGroupsState>(
        buildWhen: (before, after) => before.unreadCount != after.unreadCount,
        builder: (context, chat) => DecoratedBox(
          key: const Key('manager-bottom-navigation'),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.borderColor)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 68,
              child: Row(
                children: [
                  for (var index = 0; index < _destinations.length; index++)
                    NavigationDestinationItem(
                      icon: _destinations[index].$1,
                      label: _destinations[index].$2,
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

class NavigationDestinationItem extends StatelessWidget {
  const NavigationDestinationItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
    super.key,
  });

  final IconData icon;
  final String label;
  final int index;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkResponse(
        key: Key('nav-$index'),
        onTap: onTap,
        radius: 34,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.selected : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1 : .92,
                duration: const Duration(milliseconds: 220),
                child: Badge(
                  isLabelVisible: badgeCount > 0,
                  label: Text(badgeCount > 99 ? '99+' : '$badgeCount'),
                  child: Icon(
                    icon,
                    size: 21,
                    color: selected ? AppColors.ink : AppColors.lighterGray,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: selected ? AppColors.ink : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
