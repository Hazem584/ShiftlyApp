import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/tasks/application/tasks_cubit.dart';

import 'widgets/assigned_team_tasks_section.dart';

class AssignedTasksScreen extends StatelessWidget {
  const AssignedTasksScreen({super.key, this.taskId});

  final String? taskId;

  @override
  Widget build(BuildContext context) {
    final scope = context.watch<TasksCubit>().scope;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Assigned to you'))),
      body: scope == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AssignedTeamTasksSection(
                  key: ValueKey(scope),
                  workspaceId: scope.workspaceId,
                  isManager: false,
                  taskId: taskId,
                ),
              ],
            ),
    );
  }
}
