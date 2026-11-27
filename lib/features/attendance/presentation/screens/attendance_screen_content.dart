import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/offline/read_sync_banner.dart';
import 'package:shiftly/core/offline/read_sync_state.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_calendar_state.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_daily_status_panel.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_tab_selector.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_requests_panel.dart';
import 'package:shiftly/features/attendance/presentation/widgets/manager_attendance_panel.dart';

class AttendanceScreenContent extends StatelessWidget {
  const AttendanceScreenContent({
    required this.selectedTab,
    required this.timezone,
    required this.onRefresh,
    required this.onSelected,
    super.key,
  });

  final int selectedTab;
  final String timezone;
  final Future<void> Function() onRefresh;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('attendance-content'),
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
    children: [
      ReadSyncBanner(category: ReadCategory.attendance, onRefresh: onRefresh),
      Text(
        context.tr(
          selectedTab == 2
              ? 'Monthly calendar'
              : selectedTab == 1
              ? 'Team requests'
              : 'Team records',
        ),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      Text(
        context.tr('Workspace time · {timezone}', {'timezone': timezone}),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 20),
      AttendanceTabSelector(selectedTab: selectedTab, onSelected: onSelected),
      const SizedBox(height: AppSpacing.l),
      switch (selectedTab) {
        0 => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AttendanceDailyStatusPanel(timezone: timezone),
            ManagerAttendancePanel(timezone: timezone),
          ],
        ),
        1 => LeaveRequestsPanel(timezone: timezone),
        _ => const AttendanceCalendarStateView(editable: true),
      },
    ],
  );
}
