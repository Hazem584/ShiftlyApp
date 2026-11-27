import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/personal_task.dart';
import 'device_task_alarm_reconciler.dart';

Future<void> syncTaskNotificationRevisions(
  SharedPreferences preferences,
  String userId,
  List<PersonalTask> tasks,
) async {
  for (final task in tasks.where((t) => t.ownerId == userId)) {
    if (task.completed) {
      await preferences.setBool(
        'tasks.notification.cancelled.$userId.${task.id}',
        true,
      );
      continue;
    }
    await preferences.setInt(
      'tasks.notification.revision.$userId.${task.id}',
      task.revision,
    );
    await preferences.remove('tasks.notification.cancelled.$userId.${task.id}');
  }
}

Future<void> pruneObsoleteTaskNotifications({
  required FlutterLocalNotificationsPlugin plugin,
  required SharedPreferences preferences,
  required List<PendingNotificationRequest> pending,
  required String userId,
  required Set<String> desiredIds,
  required Map<String, int> existing,
}) async {
  for (final notification in pending) {
    final tap = decodeTaskTapPayload(notification.payload);
    if (tap == null) continue;
    final revKey = 'tasks.notification.revision.$userId.${tap['taskId']}';
    final keepSnoozed =
        tap['ownerId'] == userId &&
        tap['snoozed'] == true &&
        preferences.getBool(
              'tasks.notification.cancelled.$userId.${tap['taskId']}',
            ) !=
            true &&
        (preferences.getInt(revKey) == null ||
            preferences.getInt(revKey) == tap['revision']);
    if (!keepSnoozed &&
        (tap['ownerId'] != userId ||
            !desiredIds.contains(taskTapAlarmKey(tap)))) {
      await plugin.cancel(id: notification.id);
      existing.remove(taskTapAlarmKey(tap));
    }
  }
}
