import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/attendance/presentation/widgets/employee_leave_requests_panel.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_history_screen.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_page.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_shifts_hub.dart';

class EmployeeAttendanceScreen extends StatelessWidget {
  const EmployeeAttendanceScreen({this.initialTab = 0, super.key});
  final int initialTab;
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
    return switch (initialTab) {
      1 => EmployeePage(
        title: 'My requests',
        child: EmployeeLeaveRequestsPanel(timezone: timezone),
      ),
      2 => EmployeeHistoryScreen(timezone: timezone, calendar: true),
      3 => EmployeeHistoryScreen(timezone: timezone),
      _ => EmployeeShiftsHub(timezone: timezone),
    };
  }
}
