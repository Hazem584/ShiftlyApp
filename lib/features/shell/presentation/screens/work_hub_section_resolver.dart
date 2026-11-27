import 'package:flutter/material.dart';
import 'package:shiftly/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/fixed_shifts/presentation/screens/shift_templates_screen.dart';
import 'package:shiftly/features/reports/presentation/attendance_reports_screen.dart';
import 'package:shiftly/features/tasks/presentation/tasks_screen.dart';
import 'package:shiftly/features/team_work/presentation/team_work_screen.dart';

Widget? resolveWorkHubSection(String section, WorkspaceMembership? member) {
  final tz = member?.workspace.timezone ?? 'Etc/UTC';
  return switch (section) {
    'shifts' => ShiftTemplatesScreen(
      workspaceName: member?.workspace.name ?? 'Current workspace',
      timezone: tz,
    ),
    'tasks' => const TeamWorkScreen(initialTab: 'tasks'),
    'announcements' => const TeamWorkScreen(initialTab: 'announcements'),
    'personal' => const TasksScreen(),
    'attendance' => AttendanceScreen(timezone: tz),
    'corrections' => const TeamWorkScreen(initialTab: 'corrections'),
    'leave' => AttendanceScreen(timezone: tz, initialTab: 1),
    'calendar' => AttendanceScreen(timezone: tz, initialTab: 2),
    'reports' => const AttendanceReportsScreen(),
    _ => null,
  };
}
