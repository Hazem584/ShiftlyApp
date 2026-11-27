import 'package:flutter/material.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/fixed_shifts/presentation/screens/shift_templates_screen.dart';
import 'package:shiftly/features/reports/presentation/attendance_reports_screen.dart';
import 'package:shiftly/features/shell/presentation/screens/manager_approvals_hub_screen.dart';
import 'package:shiftly/features/shell/presentation/screens/manager_tasks_announcements_screen.dart';

Widget? resolveWorkHubSection(String section, WorkspaceMembership? member) {
  final tz = member?.workspace.timezone ?? 'Etc/UTC';
  return switch (section) {
    'shifts' => ShiftTemplatesScreen(
      workspaceName: member?.workspace.name ?? 'Current workspace',
      timezone: tz,
    ),
    'tasks' || 'attendance' || 'corrections' || 'leave' || 'calendar' =>
      ManagerApprovalsHubScreen(initialSection: section, timezone: tz),
    'personal' ||
    'announcements' => ManagerTasksAnnouncementsScreen(initialSection: section),
    'reports' => const AttendanceReportsScreen(),
    _ => null,
  };
}
