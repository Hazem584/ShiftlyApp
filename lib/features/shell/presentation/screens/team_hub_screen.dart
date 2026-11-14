import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:shiftly/features/employees/presentation/screens/add_employee_screen.dart';
import 'package:shiftly/features/employees/presentation/screens/employees_screen.dart';
import 'package:shiftly/features/reports/presentation/attendance_reports_screen.dart';
import 'package:shiftly/features/team_work/presentation/team_work_screen.dart';

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
    if (section == 'employees') return const EmployeesScreen();
    final child = switch (section) {
      'invite' => AddEmployeeScreen(onDone: () => context.go('/employees')),
      'attendance' => AttendanceScreen(timezone: timezone),
      'calendar' => AttendanceScreen(timezone: timezone, initialTab: 2),
      'leaveRequests' => AttendanceScreen(timezone: timezone, initialTab: 1),
      'corrections' => const TeamWorkScreen(initialTab: 'corrections'),
      'reports' => const AttendanceReportsScreen(),
      _ => const EmployeesScreen(),
    };
    return Column(
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => context.go('/employees'),
            icon: const BackButtonIcon(),
            label: Text(context.tr('Your team')),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
