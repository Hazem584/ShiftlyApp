import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/theme/collaboration_appearance.dart';
import 'package:shiftly/core/widgets/collaboration_session_boundary.dart';

import '../application/tasks_cubit.dart';
import '../domain/personal_task.dart';
import 'task_detail_body.dart';

Future<void> showTaskDetails(BuildContext context, PersonalTask task) =>
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<TasksCubit>(),
          child: TaskDetailScreen(task: task),
        ),
      ),
    );

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({required this.task, super.key});
  final PersonalTask task;
  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late PersonalTask _task = widget.task;
  late final FeatureSessionScope? _scope;
  @override
  void initState() {
    super.initState();
    _scope = context.read<TasksCubit>().scope;
  }

  @override
  Widget build(BuildContext context) =>
      CollaborationSessionBoundary(child: Builder(builder: _build));

  Widget _build(BuildContext context) => CollaborationAppearance(
    child: BlocConsumer<TasksCubit, TasksState>(
      listener: (c, state) {
        if (c.read<TasksCubit>().scope != _scope) {
          final route = ModalRoute.of(c);
          if (route != null) Navigator.of(c).removeRoute(route);
          return;
        }
        final next = state.items.where((t) => t.id == _task.id).firstOrNull;
        if (next != null) setState(() => _task = next);
      },
      builder: (context, state) =>
          buildTaskDetailPage(context, _task, saving: state.saving),
    ),
  );
}
