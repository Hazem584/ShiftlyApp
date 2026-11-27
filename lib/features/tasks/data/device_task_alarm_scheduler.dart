import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/personal_task.dart';
import '../domain/task_alarm.dart';
import '../domain/task_reminders.dart';
import 'device_task_alarm_installer.dart';
import 'device_task_alarm_pruner.dart';
import 'device_task_alarm_reconciler.dart';

Future<List<PersonalTask>> replaceDeviceTaskAlarms({
  required FlutterLocalNotificationsPlugin plugin,
  required SharedPreferences preferences,
  required String userId,
  required List<PersonalTask> tasks,
  required TaskReminderPermission state,
  required bool preserveExisting,
}) async {
  if (state == TaskReminderPermission.disabled) {
    for (final notification in await plugin.pendingNotificationRequests()) {
      final tap = decodeTaskTapPayload(notification.payload);
      if (tap != null &&
          !(tap['ownerId'] == userId && tap['snoozed'] == true)) {
        await plugin.cancel(id: notification.id);
      }
    }
    return [];
  }
  final pending = await plugin.pendingNotificationRequests();
  final existing = <String, int>{};
  final usedIds = pending.map((p) => p.id).toSet();
  for (final n in pending) {
    final tap = decodeTaskTapPayload(n.payload);
    if (tap?['ownerId'] == userId) existing[taskTapAlarmKey(tap!)] = n.id;
  }
  final now = DateTime.now();
  final alarms =
      tasks
          .where((t) => t.ownerId == userId)
          .expand((t) => TaskAlarm.upcoming(t, now))
          .toList()
        ..sort((a, b) {
          final c = a.at.compareTo(b.at);
          return c == 0 ? a.key.compareTo(b.key) : c;
        });
  await syncTaskNotificationRevisions(preferences, userId, tasks);
  final desiredIds = alarms.take(60).map((a) => a.key).toSet();
  if (!preserveExisting) {
    await pruneObsoleteTaskNotifications(
      plugin: plugin,
      preferences: preferences,
      pending: pending,
      userId: userId,
      desiredIds: desiredIds,
      existing: existing,
    );
  }
  return installDeviceTaskAlarms(
    plugin: plugin,
    preferences: preferences,
    userId: userId,
    tasks: tasks,
    alarms: alarms,
    existing: existing,
    usedIds: usedIds,
    state: state,
    now: now,
  );
}
