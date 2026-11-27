import 'dart:convert';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../domain/personal_task.dart';
import '../domain/task_alarm.dart';
import '../domain/task_reminders.dart';
import 'task_notification_actions.dart';

String _alarmTitle(TaskAlarm alarm, bool arabic) => switch (alarm.kind) {
  TaskAlarmKind.due => alarm.task.title,
  TaskAlarmKind.advance =>
    (arabic ? 'مهمة بكرة: ' : 'Task tomorrow: ') + alarm.task.title,
  TaskAlarmKind.hour =>
    (arabic ? 'مهمة بعد ساعة: ' : 'Task in one hour: ') + alarm.task.title,
  TaskAlarmKind.end =>
    (arabic ? 'انتهى وقت المهمة: ' : 'Time is up: ') + alarm.task.title,
};

Future<List<PersonalTask>> installDeviceTaskAlarms({
  required FlutterLocalNotificationsPlugin plugin,
  required SharedPreferences preferences,
  required String userId,
  required List<PersonalTask> tasks,
  required List<TaskAlarm> alarms,
  required Map<String, int> existing,
  required Set<int> usedIds,
  required TaskReminderPermission state,
  required DateTime now,
}) async {
  var nextId = 1700000000, occupied = existing.length;
  final installed = <String>{};
  final arabic =
      (preferences.getString('app.language') ??
          PlatformDispatcher.instance.locale.languageCode) ==
      'ar';
  for (final alarm in alarms.take(60)) {
    final task = alarm.task;
    if (!existing.containsKey(alarm.key) && occupied >= 60) continue;
    while (usedIds.contains(nextId)) {
      nextId++;
    }
    final id = existing[alarm.key] ?? nextId;
    usedIds.add(id);
    final body = task.description.isEmpty ? task.title : task.description;
    await plugin.zonedSchedule(
      id: id,
      title: _alarmTitle(alarm, arabic),
      body: body,
      scheduledDate: tz.TZDateTime.from(alarm.at, tz.UTC),
      notificationDetails: taskNotificationDetails(arabic: arabic),
      androidScheduleMode: state == TaskReminderPermission.exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: jsonEncode({
        'kind': 'personal-task',
        'ownerId': userId,
        'taskId': task.id,
        'revision': task.revision,
        'title': task.title,
        'body': body,
        'arabic': arabic,
        'reminderKind': alarm.wireKind,
        if (alarm.occurrenceDueAt != null)
          'occurrenceDueAt': alarm.occurrenceDueAt!.toUtc().toIso8601String(),
      }),
    );
    if (!existing.containsKey(alarm.key)) occupied++;
    installed.add(alarm.key);
  }
  final scheduled = tasks.where((t) {
    if (t.ownerId != userId) return false;
    final events = TaskAlarm.upcoming(t, now);
    return events.isNotEmpty && events.every((e) => installed.contains(e.key));
  }).toList()..sort((a, b) => a.dueAt.compareTo(b.dueAt));
  return state == TaskReminderPermission.exact ? scheduled : [];
}
