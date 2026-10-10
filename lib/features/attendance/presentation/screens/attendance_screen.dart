import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/screen_header.dart';
import 'package:shiftly/features/attendance/presentation/cubit/attendance_calendar_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';
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
    if (_selectedTab == 2) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<AttendanceCalendarCubit>().open(),
      );
    }
  }

  @override
  void didUpdateWidget(covariant AttendanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _selectedTab = widget.initialTab;
      if (_selectedTab == 2) {
        context.read<AttendanceCalendarCubit>().open();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => switch (_selectedTab) {
            0 => context.read<ManagerAttendanceCubit>().load(refresh: true),
            1 => context.read<LeaveRequestsCubit>().load(refresh: true),
            _ => context.read<AttendanceCalendarCubit>().load(refresh: true),
          },
          child: ListView(
            key: const Key('attendance-content'),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
            children: [
              ScreenHeader(
                icon: Icons.fact_check_rounded,
                title: context.tr('Attendance & Leave'),
                subtitle: context.tr(
                  'Check who is in, review leave, and open the calendar',
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              const AttendanceMetricsSection(),
              const SizedBox(height: AppSpacing.m),
              AttendanceTabSelector(
                selectedTab: _selectedTab,
                onSelected: (tab) {
                  setState(() => _selectedTab = tab);
                  if (tab == 2) {
                    context.read<AttendanceCalendarCubit>().open();
                  }
                },
              ),
              const SizedBox(height: AppSpacing.l),
              switch (_selectedTab) {
                0 => ManagerAttendancePanel(timezone: widget.timezone),
                1 => LeaveRequestsPanel(timezone: widget.timezone),
                _ => const AttendanceCalendarStateView(),
              },
            ],
          ),
        ),
      ),
    );
  }
}
