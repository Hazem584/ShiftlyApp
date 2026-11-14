import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:shiftly/features/fixed_shifts/presentation/screens/shift_templates_screen.dart';
import 'package:shiftly/features/reports/presentation/attendance_reports_screen.dart';
import 'package:shiftly/features/tasks/presentation/tasks_screen.dart';
import 'package:shiftly/features/team_work/presentation/team_work_screen.dart';

class WorkHubScreen extends StatelessWidget {
  const WorkHubScreen({this.section = 'hub', super.key});
  final String section;
  static const destinations = [
    ('Action inbox', 'Attendance, leave and correction decisions', 'tasks'),
    ('Shift templates', 'Hours and check-in policies', 'shifts'),
    ('My personal tasks', 'Your own to-dos and reminders', 'personal'),
    (
      'Announcements',
      'Publish updates and track acknowledgment',
      'announcements',
    ),
    ('Reports', 'Attendance summaries and exports', 'reports'),
  ];
  @override
  Widget build(BuildContext context) {
    final member = context.read<SessionCoordinator?>()?.state.activeMembership;
    final selected = switch (section) {
      'shifts' => ShiftTemplatesScreen(
        workspaceName: member?.workspace.name ?? 'Current workspace',
        timezone: member?.workspace.timezone ?? 'Etc/UTC',
      ),
      'tasks' => const TeamWorkScreen(initialTab: 'tasks'),
      'announcements' => const TeamWorkScreen(initialTab: 'announcements'),
      'personal' => const TasksScreen(),
      'attendance' => AttendanceScreen(
        timezone: member?.workspace.timezone ?? 'Etc/UTC',
      ),
      'corrections' => const TeamWorkScreen(initialTab: 'corrections'),
      'leave' => AttendanceScreen(
        timezone: member?.workspace.timezone ?? 'Etc/UTC',
        initialTab: 1,
      ),
      'calendar' => AttendanceScreen(
        timezone: member?.workspace.timezone ?? 'Etc/UTC',
        initialTab: 2,
      ),
      'reports' => const AttendanceReportsScreen(),
      _ => null,
    };
    if (selected != null) {
      return Column(
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => context.go('/work'),
              icon: const BackButtonIcon(),
              label: Text(context.tr('Work hub')),
            ),
          ),
          Expanded(child: selected),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Work hub'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            member?.workspace.name ?? context.tr('Current workspace'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          for (final item in destinations) ...[
            Card(
              child: ListTile(
                key: Key('work-destination-${item.$3}'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                title: Text(context.tr(item.$1)),
                subtitle: Text(context.tr(item.$2)),
                onTap: () => context.go('/work?tab=${item.$3}'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
