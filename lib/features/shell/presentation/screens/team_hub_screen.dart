import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:shiftly/features/employees/presentation/screens/add_employee_screen.dart';
import 'package:shiftly/features/employees/presentation/screens/employees_screen.dart';
import 'package:shiftly/features/reports/presentation/attendance_reports_screen.dart';
import 'package:shiftly/features/shell/presentation/widgets/section_navigation.dart';
import 'package:shiftly/features/team_work/presentation/team_work_screen.dart';

class TeamHubScreen extends StatelessWidget {
  const TeamHubScreen({this.section = 'employees', super.key});
  final String section;
  static const tabs = [
    ('employees', 'Employees'),
    ('invite', 'Add employee'),
    ('attendance', 'Attendance'),
    ('corrections', 'Attendance corrections'),
    ('reports', 'Attendance reports'),
  ];
  @override
  Widget build(BuildContext context) {
    final selected = tabs
        .indexWhere(
          (t) =>
              t.$1 ==
              (section == 'calendar' || section == 'leaveRequests'
                  ? 'attendance'
                  : section),
        )
        .clamp(0, tabs.length - 1);
    final timezone =
        context
            .read<SessionCoordinator?>()
            ?.state
            .activeMembership
            ?.workspace
            .timezone ??
        'Etc/UTC';
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Team & attendance'))),
      body: Column(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .34,
            ),
            child: SingleChildScrollView(
              child: SectionNavigation(
                items: tabs,
                selected: selected,
                onSelected: (index) =>
                    context.go('/employees?tab=${tabs[index].$1}'),
              ),
            ),
          ),
          Expanded(
            child: switch (tabs[selected].$1) {
              'attendance' => AttendanceScreen(
                timezone: timezone,
                initialTab: section == 'calendar'
                    ? 2
                    : section == 'leaveRequests'
                    ? 1
                    : 0,
              ),
              'invite' => AddEmployeeScreen(
                onDone: () => context.go('/employees'),
              ),
              'corrections' => const TeamWorkScreen(initialTab: 'corrections'),
              'reports' => const AttendanceReportsScreen(),
              _ => const EmployeesScreen(embedded: true),
            },
          ),
        ],
      ),
    );
  }
}
