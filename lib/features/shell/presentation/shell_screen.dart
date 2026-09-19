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
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.borderColor)),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: AppStrings.dashboard,
              ),
              NavigationDestination(
                icon: Icon(Icons.group_outlined),
                selectedIcon: Icon(Icons.group_rounded),
                label: AppStrings.employees,
              ),
              NavigationDestination(
                icon: Icon(Icons.schedule_outlined),
                selectedIcon: Icon(Icons.schedule_rounded),
                label: AppStrings.attendance,
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline_rounded),
                selectedIcon: Icon(Icons.chat_bubble_rounded),
                label: AppStrings.requests,
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: AppStrings.profile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
