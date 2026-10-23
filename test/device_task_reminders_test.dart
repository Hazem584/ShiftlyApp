import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/features/notifications/data/preferences_push_store.dart';
import 'package:shiftly/features/tasks/data/device_task_reminders.dart';
import 'package:shiftly/features/tasks/domain/personal_task.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  var exact = true;
  final calls = <MethodCall>[];
  var pending = <Map<String, Object?>>[];
  setUp(() {
    exact = true;
    calls.clear();
    pending = [];
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    SharedPreferences.setMockInitialValues({'tasks.reminders.owner': true});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'initialize':
              return true;
            case 'getNotificationAppLaunchDetails':
              return {'notificationLaunchedApp': false};
            case 'areNotificationsEnabled':
              return true;
            case 'canScheduleExactNotifications':
              return exact;
            case 'pendingNotificationRequests':
              return pending;
            default:
              return null;
          }
        });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  PersonalTask task(int i) => PersonalTask(
    id: 'task-$i',
    ownerId: 'owner',
    workspaceId: 'workspace',
    title: 'Title $i',
    description: 'Details',
    dueAt: DateTime.utc(2090, 1, i + 1, 10),
    revision: 2,
    completed: false,
  );
  Future<DeviceTaskReminders> service() async {
    final preferences = await SharedPreferences.getInstance();
    return DeviceTaskReminders(preferences, PreferencesPushStore(preferences));
  }

  Map<String, Object?> alarm(int id, PersonalTask task) => {
    'id': id,
    'title': task.title,
    'body': task.description,
    'payload': jsonEncode({
      'kind': 'personal-task',
      'ownerId': task.ownerId,
      'taskId': task.id,
      'revision': task.revision,
    }),
  };

  test('replaces retained alarms in place and frees obsolete slots before scheduling', () async {
    pending = [alarm(17, task(0)), alarm(18, task(1))];
    final reminders = await service();
    await reminders.replace('owner', [task(0), task(2)]);
    final alarms = calls.where((c) => c.method == 'zonedSchedule').toList();
    expect((alarms.first.arguments as Map)['id'], 17);
    final cancellations = calls.where((c) => c.method == 'cancel').toList();
    expect(cancellations.map((c) => (c.arguments as Map)['id']), [18]);
    expect(
      calls.indexOf(cancellations.single),
      lessThan(calls.indexOf(alarms.first)),
    );
    await reminders.close();
  });

  test('failed server withdrawal preserves existing alarms within the native limit', () async {
    pending = List.generate(60, (i) => alarm(17 + i, task(70 + i)));
    final reminders = await service();
    final scheduled = await reminders.replace('owner', [
      task(0),
    ], preserveExisting: true);
    expect(scheduled, isEmpty);
    expect(calls.where((c) => c.method == 'cancel'), isEmpty);
    expect(calls.where((c) => c.method == 'zonedSchedule'), isEmpty);
    await reminders.close();
  });

  test('schedules the nearest 60 deadlines as native UTC alarms with safe tap payloads', () async {
    final reminders = await service();
    final tasks = await reminders.replace(
      'owner',
      List.generate(70, task).reversed.toList(),
    );
    expect(tasks.length, 60);
    expect(tasks.first.id, 'task-0');
    final alarms = calls.where((c) => c.method == 'zonedSchedule').toList();
    expect(alarms.length, 60);
    final data = Map<String, Object?>.from(alarms.first.arguments as Map);
    expect(data['timeZoneName'], 'Etc/UTC');
    expect(data['scheduledDateTime'], startsWith('2090-01-01T10:00:00'));
    expect(jsonDecode(data['payload']! as String), {
      'kind': 'personal-task',
      'ownerId': 'owner',
      'taskId': 'task-0',
      'revision': 2,
    });
    await reminders.close();
  });
  test('approximate alarms never suppress server fallback', () async {
    exact = false;
    final reminders = await service();
    expect(await reminders.replace('owner', [task(0)]), isEmpty);
    expect(calls.where((c) => c.method == 'zonedSchedule'), hasLength(1));
    await reminders.close();
  });
  test('cancel removes only the chosen personal task alarm', () async {
    pending = [
      {
        'id': 17,
        'title': 'Title',
        'body': 'Details',
        'payload': jsonEncode({
          'kind': 'personal-task',
          'ownerId': 'owner',
          'taskId': 'task-0',
        }),
      },
      {
        'id': 18,
        'title': 'Other',
        'body': 'Other',
        'payload': 'another-feature',
      },
    ];
    final reminders = await service();
    await reminders.cancel('task-0');
    expect(
      calls
          .where((c) => c.method == 'cancel')
          .map((c) => (c.arguments as Map)['id']),
      [17],
    );
    await reminders.close();
  });
}
