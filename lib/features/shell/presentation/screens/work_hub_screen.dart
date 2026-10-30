import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/fixed_shifts/presentation/screens/shift_templates_screen.dart';
import 'package:shiftly/features/shell/presentation/widgets/section_navigation.dart';
import 'package:shiftly/features/tasks/presentation/tasks_screen.dart';
import 'package:shiftly/features/team_work/presentation/team_work_screen.dart';

class WorkHubScreen extends StatelessWidget {
  const WorkHubScreen({this.section = 'tasks', super.key});
  final String section;
  static const tabs = [
    ('tasks', 'Manager tasks'),
    ('shifts', 'Shifts'),
    ('announcements', 'Team announcements'),
    ('personal', 'My tasks'),
  ];
  @override
  Widget build(BuildContext context) {
    final selected = tabs
        .indexWhere((t) => t.$1 == section)
        .clamp(0, tabs.length - 1);
    final member = context.read<SessionCoordinator?>()?.state.activeMembership;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Work management'))),
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
                    context.go('/work?tab=${tabs[index].$1}'),
              ),
            ),
          ),
          Expanded(
            child: switch (tabs[selected].$1) {
              'shifts' => ShiftTemplatesScreen(
                workspaceName: member?.workspace.name ?? 'Current workspace',
                timezone: member?.workspace.timezone ?? 'Etc/UTC',
              ),
              'announcements' => const TeamWorkScreen(
                initialTab: 'announcements',
              ),
              'personal' => const TasksScreen(),
              _ => const TeamWorkScreen(initialTab: 'tasks'),
            },
          ),
        ],
      ),
    );
  }
}
