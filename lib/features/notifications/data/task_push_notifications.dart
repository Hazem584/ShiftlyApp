import 'dart:convert';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/features/tasks/data/task_notification_actions.dart';

import '../domain/entities/push_notice.dart';

@pragma('vm:entry-point')
Future<void> taskPushBackground(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  if (Firebase.apps.isEmpty) await Firebase.initializeApp();
  try {
    await showTaskPushNotification(message.data);
  } catch (_) {
    /* Durable server event remains available in-app. */
  }
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
  if (prefs.getString(taskNotificationOwnerKey) != notice.recipientProfileId ||
      prefs.getBool(
            'tasks.notification.cancelled.${notice.recipientProfileId}.${notice.taskId}',
          ) ==
          true) {
    return false;
  }
  final arabic =
      (prefs.getString('app.language') ??
          PlatformDispatcher.instance.locale.languageCode) ==
      'ar';
  final plugin = notifications ?? FlutterLocalNotificationsPlugin();
  await TaskNotificationSetup.initialize(plugin);
  await plugin.show(
    id: taskSnoozeId(notice.recipientProfileId, notice.taskId!),
    title: data['title'] as String,
    body: data['body'] as String,
    notificationDetails: taskNotificationDetails(arabic: arabic),
    payload: jsonEncode({
      'kind': 'personal-task',
      'ownerId': notice.recipientProfileId,
      'taskId': notice.taskId,
      'workspaceId': notice.workspaceId,
      if (int.tryParse(data['taskRevision']?.toString() ?? '')
          case final int revision)
        'revision': revision,
      'title': data['title'],
      'body': data['body'],
      'arabic': arabic,
    }),
  );
  await prefs.reload();
  if (prefs.getString(taskNotificationOwnerKey) != notice.recipientProfileId) {
    await plugin.cancel(
      id: taskSnoozeId(notice.recipientProfileId, notice.taskId!),
    );
    return false;
  }
  return true;
}
