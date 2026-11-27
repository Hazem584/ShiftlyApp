import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/collaboration_appearance.dart';

import '../application/tasks_cubit.dart';
import 'task_detail_screen.dart';
import 'widgets/tasks_screen_body.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({this.taskId, super.key});
  final String? taskId;
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  Timer? _refresh;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<TasksCubit>().refresh());
      unawaited(_openInitial());
    });
    _refresh = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        unawaited(context.read<TasksCubit>().refresh());
      }
    });
  }

  Future<void> _openInitial() async {
    if (widget.taskId == null) return;
    final cubit = context.read<TasksCubit>(), owner = cubit.scope?.userId;
    if (owner == null) return;
    final task = await cubit.resolveTap(owner, widget.taskId!);
    if (!mounted) return;
    if (task != null) {
      await showTaskDetails(context, task);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Task is no longer available.'))),
      );
    }
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      CollaborationAppearance(child: Builder(builder: _body));

  Widget _body(BuildContext context) => BlocConsumer<TasksCubit, TasksState>(
    listenWhen: (b, a) => a.error != null && b.error != a.error,
    listener: (context, state) =>
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.tr(state.error!)))),
    builder: (context, state) => TasksScreenBody(state: state),
  );
}
