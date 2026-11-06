import 'dart:convert';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const taskSnoozeAction = 'shiftly_task_snooze_10';
const taskNotificationCategory = 'shiftly_task_reminder';
const taskNotificationOwnerKey = 'tasks.notification.owner';

@pragma('vm:entry-point')
void taskNotificationActionBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  try {
    await snoozeTaskNotification(response);
  } catch (_) {
    /* OS may reject an alarm. */
  }
}

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

class TaskNotificationSetup {
  static void Function(NotificationResponse)? _onTap;
  static Future<void> initialize(
    FlutterLocalNotificationsPlugin plugin, {
    void Function(NotificationResponse)? onTap,
  }) async {
    if (onTap != null) _onTap = onTap;
    final prefs = await SharedPreferences.getInstance();
    final arabic =
        (prefs.getString('app.language') ??
            PlatformDispatcher.instance.locale.languageCode) ==
        'ar';
    tzdata.initializeTimeZones();
    await plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          notificationCategories: [
            DarwinNotificationCategory(
              taskNotificationCategory,
              actions: [
                DarwinNotificationAction.plain(
                  taskSnoozeAction,
                  arabic ? 'ذكّرني بعد 10 دقائق' : 'Remind me in 10 minutes',
                ),
              ],
            ),
          ],
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.actionId == taskSnoozeAction) {
          snoozeTaskNotification(response).catchError((Object _) => false);
        } else {
          _onTap?.call(response);
        }
      },
      onDidReceiveBackgroundNotificationResponse:
          taskNotificationActionBackground,
    );
  }
}

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
  final owner = payload['ownerId'] as String,
      task = payload['taskId'] as String;
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
