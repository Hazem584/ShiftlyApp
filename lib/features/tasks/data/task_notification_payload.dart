import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const taskSnoozeAction = 'shiftly_task_snooze_10';
const taskNotificationCategory = 'shiftly_task_reminder';
const taskNotificationOwnerKey = 'tasks.notification.owner';

int taskSnoozeId(String owner, String task) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode('$owner:$task')) {
    hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
  }
  return 1400000000 + hash % 100000000;
}

Map<String, dynamic>? taskNotificationPayload(String? raw) {
  try {
    final value = jsonDecode(raw ?? '');
    if (value is! Map<String, dynamic> || value['kind'] != 'personal-task') {
      return null;
    }
    for (final key in ['ownerId', 'taskId']) {
      if (value[key] is! String ||
          (value[key] as String).isEmpty ||
          (value[key] as String).length > 200) {
        return null;
      }
    }
    return value;
  } catch (_) {
    return null;
  }
}

NotificationDetails taskNotificationDetails({required bool arabic}) =>
    NotificationDetails(
      android: AndroidNotificationDetails(
        'shiftly_tasks',
        'Task reminders',
        channelDescription: 'Scheduled personal task reminders',
        importance: Importance.max,
        priority: Priority.high,
        icon: 'ic_notification',
        actions: [
          AndroidNotificationAction(
            taskSnoozeAction,
            arabic ? 'ذكّرني بعد 10 دقائق' : 'Remind me in 10 minutes',
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        categoryIdentifier: taskNotificationCategory,
      ),
    );
