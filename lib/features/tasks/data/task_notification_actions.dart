import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'task_notification_payload.dart';
import 'task_notification_setup.dart';

export 'task_notification_payload.dart';
export 'task_notification_setup.dart';

Future<bool> snoozeTaskNotification(
  NotificationResponse response, {
  FlutterLocalNotificationsPlugin? notifications,
  DateTime Function()? clock,
}) async {
  if (response.actionId != taskSnoozeAction) return false;
  final payload = taskNotificationPayload(response.payload);
  if (payload == null ||
      payload['title'] is! String ||
      payload['body'] is! String) {
    return false;
  }
  final owner = payload['ownerId'] as String;
  final task = payload['taskId'] as String;
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  bool allowed() =>
      prefs.getString(taskNotificationOwnerKey) == owner &&
      prefs.getBool('tasks.notification.cancelled.$owner.$task') != true;
  if (!allowed()) return false;
  final revision = prefs.getInt('tasks.notification.revision.$owner.$task');
  if (revision != null &&
      payload['revision'] != null &&
      payload['revision'] != revision) {
    return false;
  }
  final plugin = notifications ?? FlutterLocalNotificationsPlugin();
  await TaskNotificationSetup.initialize(plugin);
  final pending = await plugin.pendingNotificationRequests();
  final id = taskSnoozeId(owner, task);
  if (pending.length >= 64 && !pending.any((n) => n.id == id)) return false;
  final android = plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  final exact =
      android == null || await android.canScheduleExactNotifications() == true;
  final at = (clock?.call() ?? DateTime.now()).toUtc().add(
    const Duration(minutes: 10),
  );
  await plugin.zonedSchedule(
    id: id,
    title: payload['title'] as String,
    body: payload['body'] as String,
    scheduledDate: tz.TZDateTime.from(at, tz.UTC),
    notificationDetails: taskNotificationDetails(
      arabic: payload['arabic'] == true,
    ),
    androidScheduleMode: exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle,
    payload: jsonEncode({
      ...payload,
      'snoozed': true,
      'reminderKind': 'SNOOZE',
    }),
  );
  await prefs.reload();
  if (!allowed()) {
    await plugin.cancel(id: id);
    return false;
  }
  return true;
}
