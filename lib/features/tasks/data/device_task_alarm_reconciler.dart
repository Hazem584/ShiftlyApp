import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'task_notification_payload.dart';

Map<String, Object?>? decodeTaskTapPayload(String? value) {
  try {
    final json = jsonDecode(value ?? '') as Map<String, dynamic>;
    if (json['kind'] != 'personal-task' ||
        json['ownerId'] is! String ||
        json['taskId'] is! String) {
      return null;
    }
    return Map<String, Object?>.from(json);
  } catch (_) {
    return null;
  }
}

String taskTapAlarmKey(Map<String, Object?> tap) =>
    "${tap['taskId']}:${tap['reminderKind'] ?? 'DUE'}"
    "${tap['occurrenceDueAt'] is String ? ':${tap['occurrenceDueAt']}' : ''}";

Future<void> clearDeviceTaskAlarms(
  FlutterLocalNotificationsPlugin plugin,
) async {
  for (final p in await plugin.pendingNotificationRequests()) {
    if (decodeTaskTapPayload(p.payload) != null) await plugin.cancel(id: p.id);
  }
}

Future<void> cancelDeviceTaskAlarm(
  FlutterLocalNotificationsPlugin plugin,
  SharedPreferences preferences,
  String taskId,
  Future<void> Function() initialize,
) async {
  final owner = preferences.getString(taskNotificationOwnerKey);
  if (owner != null) {
    await preferences.setBool(
      'tasks.notification.cancelled.$owner.$taskId',
      true,
    );
  }
  await initialize();
  for (final p in await plugin.pendingNotificationRequests()) {
    if (decodeTaskTapPayload(p.payload)?['taskId'] == taskId) {
      await plugin.cancel(id: p.id);
    }
  }
}
