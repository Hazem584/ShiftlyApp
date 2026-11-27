import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';

import '../../domain/assigned_task_actions.dart';
import '../../domain/team_work_models.dart';
import '../cubit/work_feed_cubit.dart';
import '../dialogs/assign_team_task_dialog.dart';
import 'assigned_team_task_tile.dart';

class AssignedTeamTasksContent extends StatelessWidget {
  const AssignedTeamTasksContent({
    super.key,
    required this.workspaceId,
    required this.isManager,
    required this.actions,
    this.taskId,
  });

  final String workspaceId;
  final bool isManager;
  final AssignedTaskActions actions;
  final String? taskId;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<
        WorkFeedCubit<AssignedTeamTask>,
        WorkFeedState<AssignedTeamTask>
      >(
        builder: (context, state) {
          final cubit = context.read<WorkFeedCubit<AssignedTeamTask>>();
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        context.tr(
                          isManager ? 'Team assigned tasks' : 'Assigned to you',
                        ),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (isManager)
                        FilledButton.tonalIcon(
                          key: const Key('assign-team-task-btn'),
                          onPressed: () async {
                            if (await showAssignTeamTaskDialog(
                                  context,
                                  workspaceId: workspaceId,
                                ) &&
                                context.mounted) {
                              await cubit.load();
                            }
                          },
                          icon: const Icon(Icons.add_task_outlined),
                          label: Text(context.tr('Assign task')),
                        ),
                    ],
                  ),
                  if (state.loading && state.items.isEmpty)
                    const AppContentLoading(rows: 1)
                  else if (state.items.isEmpty && state.error == null)
                    Text(context.tr('No assigned team tasks yet.')),
                  if (state.error case final error?)
                    TextButton(
                      onPressed: () => cubit.load(),
                      child: Text(
                        '${context.tr(error)} · ${context.tr('Retry')}',
                      ),
                    ),
                  for (final task in [
                    ...state.items.where((task) => task.id == taskId),
                    ...state.items.where((task) => task.id != taskId),
                  ])
                    AssignedTeamTaskTile(
                      task: task,
                      isManager: isManager,
                      busy: state.busyId != null,
                      onStatus: (status) => cubit.mutate(
                        task.id,
                        () => actions.update(workspaceId, task.id, status),
                      ),
                      onRemind: () async {
                        final queued = await cubit.mutate(
                          task.id,
                          () => actions.remind(workspaceId, task.id),
                        );
                        if (queued && context.mounted) {
                          ToastService.success(
                            context,
                            message: 'Reminder requested',
                          );
                        }
                      },
                    ),
                ],
              ),
            ),
          );
        },
      );
}
