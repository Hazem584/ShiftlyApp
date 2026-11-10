import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/app_tab_selector.dart';
import 'package:shiftly/core/widgets/screen_header.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_attendance_calendar_cubit.dart';
import 'package:shiftly/features/attendance/presentation/widgets/employee_attendance_calendar.dart';
import 'package:shiftly/features/attendance/presentation/widgets/employee_attendance_history.dart';
import 'package:shiftly/features/attendance/presentation/widgets/employee_leave_requests_panel.dart';

class EmployeeAttendanceScreen extends StatefulWidget {
  const EmployeeAttendanceScreen({this.initialTab = 0, super.key});

  final int initialTab;

  @override
  State<EmployeeAttendanceScreen> createState() =>
      _EmployeeAttendanceScreenState();
}

class _EmployeeAttendanceScreenState extends State<EmployeeAttendanceScreen> {
  late int _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _tab == 2) {
        context.read<EmployeeAttendanceCalendarCubit>().open();
      }
    });
  }

  @override
  void didUpdateWidget(covariant EmployeeAttendanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _tab = widget.initialTab;
      if (_tab == 2) context.read<EmployeeAttendanceCalendarCubit>().open();
    }
  }

  @override
  Widget build(BuildContext context) {
    final timezone =
        context
            .watch<SessionCoordinator>()
            .state
            .activeMembership
            ?.workspace
            .timezone ??
        'Etc/UTC';
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScreenHeader(
                  title: context.tr('My Shifts'),
                  subtitle: context.tr(
                    'Your workspace attendance and leave requests',
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                AppTabSelector(
                  labels: const ['Attendance', 'Leave', 'Calendar'],
                  selectedIndex: _tab,
                  onSelected: (selected) {
                    setState(() => _tab = selected);
                    if (selected == 2) {
                      context.read<EmployeeAttendanceCalendarCubit>().open();
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (_tab) {
              0 => EmployeeAttendanceHistory(timezone: timezone),
              1 => EmployeeLeaveRequestsPanel(timezone: timezone),
              _ => const EmployeeAttendanceCalendar(),
            },
          ),
        ],
      ),
    );
  }
}
