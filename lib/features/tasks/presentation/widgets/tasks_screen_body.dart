import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/tasks/application/tasks_cubit.dart';
import 'package:shiftly/features/tasks/presentation/task_options_sheet.dart';
import 'package:shiftly/features/tasks/presentation/widgets/task_editor.dart';
import 'package:shiftly/features/tasks/presentation/widgets/tasks_header_and_filters.dart';
import 'package:shiftly/features/tasks/presentation/widgets/tasks_list_content.dart';

class TasksScreenBody extends StatelessWidget {
  const TasksScreenBody({required this.state, super.key});
  final TasksState state;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildTasksHeader(
                context,
                completed: state.completed,
                onOptions: () => openTaskOptionsMenu(context),
              ),
              Expanded(child: TasksListContent(state: state)),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 10),
                child: FilledButton(
                  key: const Key('add-personal-task'),
                  onPressed: state.saving
                      ? null
                      : () => showTaskEditor(context),
                  child: Text(context.tr('Add task')),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
