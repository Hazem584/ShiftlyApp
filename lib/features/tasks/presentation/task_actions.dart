import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import '../application/tasks_cubit.dart';
import '../domain/personal_task.dart';

Future<bool> confirmTaskAction(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(c.tr(title)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(c.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(c.tr(action)),
          ),
        ],
      ),
    ) ==
    true;
Future<bool> togglePersonalTask(BuildContext context, PersonalTask task) async {
  final cubit = context.read<TasksCubit>();
  final scope = cubit.scope;
  if (task.completed &&
      !await confirmTaskAction(
        context,
        title: 'Reopen this task?',
        message: context.tr(
          'This task will return to your open tasks. Eligible reminders will be restored.',
        ),
        action: 'Reopen task',
      )) {
    return false;
  }
  if (!context.mounted || cubit.scope != scope) return false;
  final success = await cubit.toggle(task);
  if (success && context.mounted && cubit.scope == scope) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr(task.completed ? 'Task reopened' : 'Task complete'),
        ),
      ),
    );
  }
  return success;
}

Future<bool> deletePersonalTask(BuildContext context, PersonalTask task) async {
  final cubit = context.read<TasksCubit>();
  final scope = cubit.scope;
  if (!await confirmTaskAction(
    context,
    title: 'Delete this task?',
    message: context.tr(
      'This permanently deletes the task and cancels its reminder.',
    ),
    action: 'Delete task',
  )) {
    return false;
  }
  if (!context.mounted || cubit.scope != scope) return false;
  return cubit.remove(task);
}
