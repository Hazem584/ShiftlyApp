import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/features/notifications/data/task_push_notifications.dart';
import 'package:shiftly/features/tasks/data/task_notification_actions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const owner = '11111111-1111-4111-8111-111111111111';
  const task = '22222222-2222-4222-8222-222222222222';
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];
  final data = <String, dynamic>{
    'notificationId': '33333333-3333-4333-8333-333333333333',
    'workspaceId': '44444444-4444-4444-8444-444444444444',
    'recipientProfileId': owner,
    'taskId': task,
    'taskRevision': '2',
    'taskActionsVersion': '1',
    'title': 'Do the task',
    'body': 'Details',
  };
  setUp(() {
    calls.clear();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    SharedPreferences.setMockInitialValues({
      taskNotificationOwnerKey: owner,
      'app.language': 'ar',
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (c) async {
          calls.add(c);
          return c.method == 'initialize' ? true : null;
        });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  test(
    'background task data becomes one actionable local notification',
    () async {
      expect(await showTaskPushNotification(data), isTrue);
      final shown =
          calls.where((c) => c.method == 'show').single.arguments as Map;
      expect(shown['title'], 'Do the task');
      final payload = jsonDecode(shown['payload'] as String) as Map;
      expect(payload['ownerId'], owner);
      expect(payload['taskId'], task);
      expect(payload['revision'], 2);
      final action =
          (((shown['platformSpecifics'] as Map)['actions']) as List).single
              as Map;
      expect(action['showsUserInterface'], isFalse);
      expect(action['id'], taskSnoozeAction);
    },
  );
  test('ignores non-task pushes and stale account notices', () async {
    expect(
      await showTaskPushNotification({...data, 'taskActionsVersion': '0'}),
      isFalse,
    );
    expect(
      await showTaskPushNotification({
        ...data,
        'recipientProfileId': '55555555-5555-4555-8555-555555555555',
      }),
      isFalse,
    );
    expect(await showTaskPushNotification({...data, 'taskId': null}), isFalse);
    expect(calls.where((c) => c.method == 'show'), isEmpty);
  });
}
