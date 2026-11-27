import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/tasks/presentation/tasks_screen.dart';
import 'package:shiftly/features/team_work/presentation/team_work_screen.dart';

class ManagerTasksAnnouncementsScreen extends StatefulWidget {
  const ManagerTasksAnnouncementsScreen({
    super.key,
    required this.initialSection,
  });
  final String initialSection;

  @override
  State<ManagerTasksAnnouncementsScreen> createState() =>
      _ManagerTasksAnnouncementsScreenState();
}

class _ManagerTasksAnnouncementsScreenState
    extends State<ManagerTasksAnnouncementsScreen> {
  late String _tab = widget.initialSection == 'announcements'
      ? 'announcements'
      : 'personal';

  @override
  void didUpdateWidget(covariant ManagerTasksAnnouncementsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSection != widget.initialSection) {
      _tab = widget.initialSection == 'announcements'
          ? 'announcements'
          : 'personal';
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              key: const Key('hub-tab-personal-tasks'),
              label: Text(context.tr('My personal tasks')),
              selected: _tab == 'personal',
              onSelected: (_) => setState(() => _tab = 'personal'),
            ),
            ChoiceChip(
              key: const Key('hub-tab-announcements'),
              label: Text(context.tr('Announcements')),
              selected: _tab == 'announcements',
              onSelected: (_) => setState(() => _tab = 'announcements'),
            ),
          ],
        ),
      ),
      Expanded(
        child: _tab == 'announcements'
            ? const TeamWorkScreen(initialTab: 'announcements')
            : const TasksScreen(),
      ),
    ],
  );
}
