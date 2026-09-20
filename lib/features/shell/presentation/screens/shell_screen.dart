import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/features/shell/presentation/widgets/app_bottom_navigation.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: navigationShell,
    bottomNavigationBar: AppBottomNavigation(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      ),
    ),
  );
}
