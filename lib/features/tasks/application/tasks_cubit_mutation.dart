import 'dart:async';

import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/session/feature_scope.dart';

import '../domain/personal_task.dart';
import '../domain/task_reminders.dart';
import '../domain/task_repository.dart';
import 'tasks_state.dart';

Future<bool> runTaskMutation({
  required FeatureSessionScope? scope,
  required TasksState Function() getState,
  required void Function(TasksState) emitState,
  required bool Function() isValid,
  required Future<void> Function(FeatureSessionScope) action,
  required PersonalTask? changedTask,
  required void Function() clearSignature,
  required Future<void> Function(Future<void> Function()) enqueueReminder,
  required TaskReminders reminders,
  required Future<void> Function() refresh,
  required Future<void> Function() syncReminders,
}) async {
  if (scope == null ||
      getState().saving ||
      (changedTask != null && changedTask.ownerId != scope.userId)) {
    return false;
  }
  emitState(getState().copy(saving: true));
  try {
    await action(scope);
    if (!isValid()) return false;
    if (changedTask != null) {
      clearSignature();
      await enqueueReminder(() => reminders.cancel(changedTask.id));
      if (!isValid()) return false;
    }
    emitState(getState().copy(saving: false));
    await refresh();
    return isValid();
  } catch (error) {
    if (isValid()) {
      emitState(
        getState().copy(
          saving: false,
          error: ApiErrorParser.parse(error).message,
        ),
      );
      unawaited(syncReminders());
    }
    return false;
  }
}

Future<PersonalTask?> resolveOwnerTaskTap(
  TaskRepository repository,
  FeatureSessionScope? scope,
  String ownerId,
  String taskId,
  bool Function() isValid,
) async {
  if (scope?.userId != ownerId) return null;
  try {
    final task = await repository.get(taskId);
    return isValid() && task.ownerId == ownerId ? task : null;
  } catch (_) {
    return null;
  }
}
