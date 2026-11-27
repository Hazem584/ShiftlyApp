import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import '../../domain/team_work_models.dart';

class AssignedTeamTaskTile extends StatelessWidget {
  const AssignedTeamTaskTile({
    super.key,
    required this.task,
    required this.isManager,
    required this.busy,
    required this.onStatus,
    required this.onRemind,
  });

  final AssignedTeamTask task;
  final bool isManager, busy;
  final ValueChanged<String> onStatus;
  final VoidCallback onRemind;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(task.title),
    subtitle: Text(
      '${isManager ? task.assigneeName : task.createdByName} · '
      '${context.tr(task.priority)} · ${context.tr(task.status)}',
    ),
    trailing: isManager
        ? IconButton(
            tooltip: context.tr('Remind employee'),
            onPressed: busy || task.status == 'COMPLETED' ? null : onRemind,
            icon: const Icon(Icons.notifications_active_outlined),
          )
        : PopupMenuButton<String>(
            tooltip: context.tr('Change task status'),
            enabled: !busy,
            onSelected: onStatus,
            itemBuilder: (_) => [
              for (final status in const ['OPEN', 'IN_PROGRESS', 'COMPLETED'])
                CheckedPopupMenuItem(
                  value: status,
                  enabled: status != task.status,
                  checked: status == task.status,
                  child: Text(context.tr(status)),
                ),
            ],
          ),
  );
}
