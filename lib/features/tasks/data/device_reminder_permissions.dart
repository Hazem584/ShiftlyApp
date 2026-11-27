import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/task_reminders.dart';

Future<TaskReminderPermission> resolveDeviceReminderPermission(
  FlutterLocalNotificationsPlugin plugin,
  SharedPreferences preferences,
  String userId, {
  bool request = false,
}) async {
  if (request) await preferences.setBool('tasks.reminders.$userId', true);
  if (!(preferences.getBool('tasks.reminders.$userId') ?? false)) {
    return TaskReminderPermission.disabled;
  }
  final android = plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  if (android != null) {
    final allowed = request
        ? await android.requestNotificationsPermission()
        : await android.areNotificationsEnabled();
    if (allowed != true) return TaskReminderPermission.disabled;
    final exact = request
        ? await android.requestExactAlarmsPermission()
        : await android.canScheduleExactNotifications();
    return exact == true
        ? TaskReminderPermission.exact
        : TaskReminderPermission.approximate;
  }
  final ios = plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >()!;
  if (request) {
    await ios.requestPermissions(alert: true, badge: true, sound: true);
  }
  final permissions = await ios.checkPermissions();
  return permissions?.isEnabled == true
      ? TaskReminderPermission.exact
      : TaskReminderPermission.disabled;
}
