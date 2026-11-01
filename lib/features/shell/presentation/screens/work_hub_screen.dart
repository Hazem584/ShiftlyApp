import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/fixed_shifts/presentation/screens/shift_templates_screen.dart';
import 'package:shiftly/features/reports/presentation/attendance_reports_screen.dart';
import 'package:shiftly/features/tasks/presentation/tasks_screen.dart';
import 'package:shiftly/features/team_work/presentation/team_work_screen.dart';

class WorkHubScreen extends StatelessWidget {
  const WorkHubScreen({this.section = 'overview', super.key});
  final String section;
  static const destinations = [
    (
      'tasks',
      'Action inbox',
      'Attendance, leave and correction decisions',
      Icons.fact_check_outlined,
    ),
    (
      'shifts',
      'Shift templates',
      'Hours and check-in policies',
      Icons.schedule_outlined,
    ),
    (
      'personal',
      'My personal tasks',
      'Your own to-dos and reminders',
      Icons.checklist_outlined,
    ),
    (
      'announcements',
      'Announcements',
      'Publish updates and track acknowledgment',
      Icons.campaign_outlined,
    ),
    (
      'reports',
      'Reports',
      'Attendance summaries and exports',
      Icons.assessment_outlined,
    ),
  ];
  @override
  Widget build(BuildContext context) {
    final member = context.read<SessionCoordinator?>()?.state.activeMembership;
    if (section == 'shifts') {
      return ShiftTemplatesScreen(
        workspaceName:
            member?.workspace.name ?? context.tr('Current workspace'),
        timezone: member?.workspace.timezone ?? 'Etc/UTC',
      );
    }
    if (section == 'personal') return const TasksScreen();
    if (section == 'reports') return const AttendanceReportsScreen();
    if (section == 'announcements' || section == 'tasks') {
      return TeamWorkScreen(initialTab: section);
    }
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Work hub'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            member?.workspace.name ?? context.tr('Current workspace'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 32),
          for (final item in destinations)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SurfaceCard(
                key: Key('section-${item.$1}'),
                onTap: () => context.go('/work?tab=${item.$1}'),
                child: Row(
                  children: [
                    Icon(item.$4),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(item.$2),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr(item.$3),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
