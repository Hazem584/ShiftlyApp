import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/widgets/workspace_content_frame.dart';
import 'package:shiftly/features/shell/presentation/widgets/app_bottom_navigation.dart';
import 'package:shiftly/features/shell/presentation/widgets/workspace_navigation_rail.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 840 && constraints.maxHeight >= 600;
      void select(int index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );
      return Scaffold(
        body: Row(
          children: [
            if (wide) ...[
              WorkspaceNavigationRail(
                extended: constraints.maxWidth >= 1200,
                selectedIndex: navigationShell.currentIndex,
                onSelected: select,
              ),
              const VerticalDivider(width: 1),
            ],
            Expanded(
              child: WorkspaceContentFrame(
                framed: wide,
                child: navigationShell,
              ),
            ),
          ],
        ),
        bottomNavigationBar: wide
            ? null
            : AppBottomNavigation(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: select,
              ),
      );
    },
  );
}
