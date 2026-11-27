import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/di/service_locator.dart';

import '../../domain/assigned_task_actions.dart';
import '../../domain/team_work_models.dart';
import '../../domain/team_work_repository.dart';
import '../cubit/work_feed_cubit.dart';
import 'assigned_team_tasks_content.dart';

class AssignedTeamTasksSection extends StatelessWidget {
  const AssignedTeamTasksSection({
    super.key,
    required this.workspaceId,
    required this.isManager,
    this.taskId,
  });

  final String workspaceId;
  final bool isManager;
  final String? taskId;

  @override
  Widget build(BuildContext context) {
    if (workspaceId.isEmpty || !getIt.isRegistered<TeamWorkRepository>()) {
      return const SizedBox.shrink();
    }
    final actions = AssignedTaskActions(getIt<TeamWorkRepository>());
    return BlocProvider(
      key: ValueKey(workspaceId),
      create: (_) =>
          WorkFeedCubit<AssignedTeamTask>((_) => actions.load(workspaceId))
            ..load(),
      child: AssignedTeamTasksContent(
        workspaceId: workspaceId,
        isManager: isManager,
        actions: actions,
        taskId: taskId,
      ),
    );
  }
}
