import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';

class AttendanceTabSelector extends StatelessWidget {
  const AttendanceTabSelector({
    required this.selectedTab,
    required this.onSelected,
    super.key,
  });
  final int selectedTab;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => SegmentedButton<int>(
    showSelectedIcon: false,
    segments: const [
      ButtonSegment(
        value: 0,
        label: Text('Attendance', key: Key('attendance-tab-records')),
      ),
      ButtonSegment(
        value: 1,
        label: Text('Leave Requests', key: Key('attendance-tab-requests')),
      ),
      ButtonSegment(
        value: 2,
        label: Text('Calendar', key: Key('attendance-tab-calendar')),
      ),
    ],
    selected: {selectedTab},
    onSelectionChanged: (value) => onSelected(value.first),
    style: ButtonStyle(
      visualDensity: VisualDensity.compact,
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.surface
            : AppColors.field,
      ),
      foregroundColor: const WidgetStatePropertyAll(AppColors.ink),
      side: const WidgetStatePropertyAll(
        BorderSide(color: AppColors.borderColor),
      ),
    ),
  );
}
