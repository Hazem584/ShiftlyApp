import 'package:flutter/material.dart';
import 'package:shiftly/core/widgets/workspace_content_frame.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_bottom_navigation.dart';
import 'package:shiftly/features/shell/presentation/screens/employee_shell_tabs.dart';
import 'package:shiftly/features/shell/presentation/widgets/workspace_navigation_rail.dart';

class EmployeeShellScreen extends StatefulWidget {
  const EmployeeShellScreen({
    this.initialTab = 0,
    this.initialAttendanceTab = 0,
    super.key,
  });

  final int initialTab;
  final int initialAttendanceTab;

  @override
  State<EmployeeShellScreen> createState() => _EmployeeShellScreenState();
}

class _EmployeeShellScreenState extends State<EmployeeShellScreen> {
  late int _selectedIndex = widget.initialTab;

  @override
  void didUpdateWidget(covariant EmployeeShellScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _selectedIndex = widget.initialTab;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 840 && size.height >= 600;
    return PopScope<Object?>(
      canPop: _selectedIndex == 0 || Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _selectedIndex = 0);
      },
      child: Scaffold(
        body: Row(
          children: [
            if (wide) ...[
              WorkspaceNavigationRail(
                extended: size.width >= 1200,
                employee: true,
                selectedIndex: _selectedIndex,
                onSelected: (index) => setState(() => _selectedIndex = index),
              ),
              const VerticalDivider(width: 1),
            ],
            Expanded(
              child: WorkspaceContentFrame(
                framed: wide,
                child: SafeArea(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: buildEmployeeShellTabs(
                      context,
                      selectedIndex: _selectedIndex,
                      initialAttendanceTab: widget.initialAttendanceTab,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: wide
            ? null
            : EmployeeBottomNavigation(
                selectedIndex: _selectedIndex,
                onSelected: (index) => setState(() => _selectedIndex = index),
              ),
      ),
    );
  }
}
