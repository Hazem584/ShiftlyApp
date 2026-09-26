import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/screen_header.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_cubit.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_calendar_state.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_metrics_section.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_tab_selector.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_requests_panel.dart';
import 'package:shiftly/features/attendance/presentation/widgets/manager_attendance_panel.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({
    this.initialTab = 0,
    this.timezone = 'Etc/UTC',
    super.key,
  });

  final int initialTab;
  final String timezone;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  void didUpdateWidget(covariant AttendanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _selectedTab = widget.initialTab;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _selectedTab == 0
              ? () => context.read<ManagerAttendanceCubit>().load(refresh: true)
              : () async {},
          child: ListView(
            key: const Key('attendance-content'),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
            children: [
              const ScreenHeader(
                title: 'Attendance & Leave',
                subtitle: 'Track attendance and manage leave requests',
              ),
              const SizedBox(height: AppSpacing.m),
              const AttendanceMetricsSection(),
              const SizedBox(height: AppSpacing.m),
              AttendanceTabSelector(
                selectedTab: _selectedTab,
                onSelected: (tab) => setState(() => _selectedTab = tab),
              ),
              const SizedBox(height: AppSpacing.l),
              switch (_selectedTab) {
                0 => ManagerAttendancePanel(timezone: widget.timezone),
                1 => const LeaveRequestsPanel(),
                _ => const AttendanceCalendarState(),
              },
            ],
          ),
        ),
      ),
    );
  }
}
