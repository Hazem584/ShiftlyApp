import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/features/notifications/data/task_push_payload.dart';
import 'package:shiftly/features/notifications/domain/entities/push_notice.dart';
import 'package:shiftly/features/tasks/data/task_notification_actions.dart';

@pragma('vm:entry-point')
Future<void> taskPushBackground(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  if (Firebase.apps.isEmpty) await Firebase.initializeApp();
  try {
    await showTaskPushNotification(message.data);
  } catch (_) {}
}

Future<bool> showTaskPushNotification(
  Map<String, dynamic> data, {
  FlutterLocalNotificationsPlugin? notifications,
}) async {
  if (data['taskActionsVersion'] != '1') return false;
  final notice = PushNotice.fromData(data);
  if (notice == null ||
      notice.taskId == null ||
      data['title'] is! String ||
      data['body'] is! String) {
    return false;
  }
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  if (!isTaskPushEligible(prefs, notice)) return false;
  final arabic = isTaskPushArabic(prefs);
  final plugin = notifications ?? FlutterLocalNotificationsPlugin();
  await TaskNotificationSetup.initialize(plugin);
  final notificationId = taskSnoozeId(
    notice.recipientProfileId,
    notice.taskId!,
  );
  await plugin.show(
    id: notificationId,
    title: data['title'] as String,
    body: data['body'] as String,
    notificationDetails: taskNotificationDetails(arabic: arabic),
    payload: encodeTaskPushPayload(notice, data, arabic: arabic),
  );
  await prefs.reload();
  if (prefs.getString(taskNotificationOwnerKey) != notice.recipientProfileId) {
    await plugin.cancel(id: notificationId);
    return false;
  }
  return true;
}
