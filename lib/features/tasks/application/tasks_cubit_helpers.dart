import 'package:shiftly/core/session/feature_scope.dart';

import '../domain/personal_task.dart';
import '../domain/task_alarm.dart';
import '../domain/task_reminders.dart';
import '../domain/task_repository.dart';

Future<void> syncTaskRemindersFlow({
  required TaskRepository repository,
  required TaskReminders reminders,
  required String user,
  required bool request,
  required DateTime Function() clock,
  required Future<void> Function()? enableRemoteReminders,
  required bool Function() isValid,
  required String? Function() getLastSignature,
  required void Function(String?) setLastSignature,
  required void Function(TaskReminderPermission) onPermission,
  required void Function() onError,
}) async {
  try {
    final permission = await reminders.permission(user, request: request);
    if (request && isValid()) await enableRemoteReminders?.call();
    if (!isValid()) return;
    onPermission(permission);
    final tasks = await repository.upcoming();
    if (!isValid()) return;
    final now = clock();
    final signature =
        '$user:$permission:${tasks.map((t) => '${t.id}:${t.revision}:'
            '${TaskAlarm.upcoming(t, now).map((a) => a.key).join('+')}').join(',')}';
    if (signature == getLastSignature()) return;
    final installation = await reminders.installationId();
    var registrationFailed = false;
    if (installation != null) {
      try {
        await repository.register(installation, []);
      } catch (_) {
        registrationFailed = true;
      }
    }
    if (!isValid()) return;
    final scheduled = await reminders.replace(
      user,
      tasks,
      preserveExisting: registrationFailed,
    );
    if (!isValid()) {
      await reminders.clear();
      return;
    }
    if (installation != null) {
      try {
        await repository.register(installation, scheduled);
      } catch (_) {
        registrationFailed = true;
      }
    }
    if (!isValid()) return;
    setLastSignature(registrationFailed ? null : signature);
    if (registrationFailed) onError();
  } catch (_) {
    setLastSignature(null);
    if (isValid()) onError();
  }
}

Future<void> savePersonalTask(
  TaskRepository repository,
  FeatureSessionScope scope, {
  PersonalTask? task,
  required String title,
  required String description,
  required DateTime dueAt,
  int? durationMinutes,
  required bool remindDayBefore,
  required bool remindHourBefore,
  required List<DateTime> additionalDueAts,
}) => task == null
    ? repository.create(
        workspaceId: scope.workspaceId,
        title: title.trim(),
        description: description.trim(),
        dueAt: dueAt,
        durationMinutes: durationMinutes,
        remindDayBefore: remindDayBefore,
        remindHourBefore: remindHourBefore,
        additionalDueAts: additionalDueAts,
      )
    : repository.update(
        task,
        title: title.trim(),
        description: description.trim(),
        dueAt: dueAt.isAtSameMomentAs(task.dueAt) ? null : dueAt,
        durationMinutes: durationMinutes,
        remindDayBefore: remindDayBefore,
        remindHourBefore: remindHourBefore,
        additionalDueAts: additionalDueAts,
      );
