import 'package:flutter/material.dart';
import 'package:shiftly/core/widgets/app_tab_selector.dart';

class AttendanceTabSelector extends StatelessWidget {
  const AttendanceTabSelector({
    required this.selectedTab,
    required this.onSelected,
    super.key,
  });
  final int selectedTab;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => AppTabSelector(
    labels: const ['Attendance', 'Leave Requests', 'Calendar'],
    labelKeys: const [
      Key('attendance-tab-records'),
      Key('attendance-tab-requests'),
      Key('attendance-tab-calendar'),
    ],
    selectedIndex: selectedTab,
    onSelected: onSelected,
  );
}
