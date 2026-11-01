import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:shiftly/features/employees/presentation/screens/add_employee_screen.dart';
import 'package:shiftly/features/employees/presentation/screens/employees_screen.dart';
import 'package:shiftly/features/reports/presentation/attendance_reports_screen.dart';
import 'package:shiftly/features/team_work/presentation/team_work_screen.dart';

/// Legacy tab URLs remain valid, while each destination owns one screen header.
class TeamHubScreen extends StatelessWidget {
  const TeamHubScreen({this.section = 'employees', super.key});
  final String section;
  @override
  Widget build(BuildContext context) {
    final timezone =
        context
            .read<SessionCoordinator?>()
            ?.state
            .activeMembership
            ?.workspace
            .timezone ??
        'Etc/UTC';
    return switch (section) {
      'attendance' || 'calendar' || 'leaveRequests' => AttendanceScreen(
        timezone: timezone,
        initialTab: section == 'calendar'
            ? 2
            : section == 'leaveRequests'
            ? 1
            : 0,
      ),
      'invite' => const AddEmployeeScreen(),
      'corrections' => const TeamWorkScreen(initialTab: 'corrections'),
      'reports' => const AttendanceReportsScreen(),
      _ => const EmployeesScreen(),
    };
  }
}
