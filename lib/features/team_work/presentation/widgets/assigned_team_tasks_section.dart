import 'package:flutter/material.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/assign_team_task_dialog.dart';

class AssignedTeamTasksSection extends StatefulWidget {
  const AssignedTeamTasksSection({
    super.key,
    required this.workspaceId,
    required this.isManager,
  });
  final String workspaceId;
  final bool isManager;
  @override
  State<AssignedTeamTasksSection> createState() =>
      _AssignedTeamTasksSectionState();
}

class _AssignedTeamTasksSectionState extends State<AssignedTeamTasksSection> {
  List<AssignedTeamTask> _tasks = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!getIt.isRegistered<TeamWorkRepository>() ||
        widget.workspaceId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final list = await getIt<TeamWorkRepository>().assignedTasks(
        widget.workspaceId,
      );
      if (mounted) setState(() => _tasks = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cycleStatus(AssignedTeamTask task) async {
    final next = switch (task.status) {
      'OPEN' => 'IN_PROGRESS',
      'IN_PROGRESS' => 'COMPLETED',
      _ => 'OPEN',
    };
    await getIt<TeamWorkRepository>().updateAssignedTaskStatus(
      widget.workspaceId,
      task.id,
      next,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr(
                    widget.isManager
                        ? 'Team assigned tasks'
                        : 'Assigned to you',
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (widget.isManager)
                FilledButton.tonalIcon(
                  key: const Key('assign-team-task-btn'),
                  onPressed: () async {
                    if (await showAssignTeamTaskDialog(
                      context,
                      workspaceId: widget.workspaceId,
                    )) {
                      await _load();
                    }
                  },
                  icon: const Icon(Icons.add_task_outlined, size: 18),
                  label: Text(context.tr('Assign task')),
                ),
            ],
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: LinearProgressIndicator(),
            )
          else if (_tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(context.tr('No assigned team tasks yet.')),
            )
          else
            for (final t in _tasks)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.title),
                subtitle: Text(
                  '${t.assigneeName} · ${context.tr(t.priority)} · ${context.tr(t.status)}',
                ),
                trailing: ActionChip(
                  label: Text(context.tr(t.status)),
                  onPressed: () => _cycleStatus(t),
                ),
              ),
        ],
      ),
    ),
  );
}
