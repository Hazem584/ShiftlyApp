import 'package:flutter/material.dart';
import 'package:shiftly/core/constants/app_strings.dart';
import 'package:shiftly/core/theme/app_colors.dart';

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
    (Icons.person_rounded, AppStrings.profile),
  ];

  @override
  Widget build(BuildContext context) => DecoratedBox(
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
              ),
          ],
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
    super.key,
  });

  final IconData icon;
  final String label;
  final int index;
  final bool selected;
  final VoidCallback onTap;

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
                child: Icon(
                  icon,
                  size: 21,
                  color: selected ? AppColors.ink : AppColors.lighterGray,
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
