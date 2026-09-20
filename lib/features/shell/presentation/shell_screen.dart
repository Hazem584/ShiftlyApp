import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/constants/app_strings.dart';
import 'package:shiftly/core/theme/app_colors.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
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
                _Destination(
                  icon: Icons.home_rounded,
                  label: AppStrings.dashboard,
                  index: 0,
                  shell: navigationShell,
                ),
                _Destination(
                  icon: Icons.groups_rounded,
                  label: AppStrings.employees,
                  index: 1,
                  shell: navigationShell,
                ),
                _Destination(
                  icon: Icons.schedule_rounded,
                  label: AppStrings.attendance,
                  index: 2,
                  shell: navigationShell,
                ),
                _Destination(
                  icon: Icons.person_rounded,
                  label: AppStrings.profile,
                  index: 3,
                  shell: navigationShell,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Destination extends StatelessWidget {
  const _Destination({
    required this.icon,
    required this.label,
    required this.index,
    required this.shell,
  });
  final IconData icon;
  final String label;
  final int index;
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final selected = shell.currentIndex == index;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: InkResponse(
          key: Key('nav-$index'),
          onTap: () => shell.goBranch(index, initialLocation: selected),
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
}
