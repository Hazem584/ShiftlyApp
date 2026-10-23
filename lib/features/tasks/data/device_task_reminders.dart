import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_preference_store.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/personal_task.dart';
import '../domain/task_reminders.dart';

/// Native pending alarms survive process death and Android reboot. UTC preserves
/// the chosen instant across timezone changes; the editor uses device local time.
class DeviceTaskReminders implements TaskReminders {
  DeviceTaskReminders(this._preferences, this._pushStore);
  final SharedPreferences _preferences;
  final PushPreferenceStore _pushStore;
  final _plugin = FlutterLocalNotificationsPlugin();
  final opened = StreamController<Map<String, Object?>>.broadcast();
  Map<String, Object?>? initialTap;
  Future<void>? _initializing;
  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  Future<void> _initialize() => _initializing ??= _start();
  Future<void> _start() async {
    if (!_supported) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final tap = _decode(response.payload);
        if (tap != null) opened.add(tap);
      },
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      initialTap = _decode(launch?.notificationResponse?.payload);
    }
  }

  Map<String, Object?>? _decode(String? value) {
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

  @override
  Future<TaskReminderPermission> permission(
    String userId, {
    bool request = false,
  }) async {
    if (!_supported) return TaskReminderPermission.unsupported;
    await _initialize();
    if (request) await _preferences.setBool('tasks.reminders.$userId', true);
    if (!(_preferences.getBool('tasks.reminders.$userId') ?? false)) {
      return TaskReminderPermission.disabled;
    }
    final android = _plugin
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
    final ios = _plugin
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

  @override
  Future<List<PersonalTask>> replace(
    String userId,
    List<PersonalTask> tasks, {
    bool preserveExisting = false,
  }) async {
    if (!_supported) return [];
    await _initialize();
    final state = await permission(userId);
    if (state == TaskReminderPermission.disabled) {
      await clear();
      return [];
    }
    final pending = await _plugin.pendingNotificationRequests();
    final existing = <String, int>{};
    final usedIds = pending.map((p) => p.id).toSet();
    for (final notification in pending) {
      final tap = _decode(notification.payload);
      if (tap?['ownerId'] == userId) {
        existing[tap!['taskId']! as String] = notification.id;
      }
    }
    var nextId = 1700000000;
    final scheduled = <PersonalTask>[];
    final sorted =
        tasks
            .where(
              (t) =>
                  t.ownerId == userId &&
                  !t.completed &&
                  t.dueAt.isAfter(DateTime.now()),
            )
            .toList()
          ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    final desiredIds = sorted.take(60).map((t) => t.id).toSet();
    if (!preserveExisting) {
      // Free obsolete slots first so reconciliation never exceeds iOS's cap.
      for (final notification in pending) {
        final tap = _decode(notification.payload);
        if (tap != null &&
            (tap['ownerId'] != userId || !desiredIds.contains(tap['taskId']))) {
          await _plugin.cancel(id: notification.id);
          existing.remove(tap['taskId']);
        }
      }
    }
    var occupied = existing.length;
    // Reserve four iOS slots for other app reminders (system limit is 64).
    for (final task in sorted.take(60)) {
      if (!existing.containsKey(task.id) && occupied >= 60) continue;
      while (usedIds.contains(nextId)) {
        nextId++;
      }
      final id = existing[task.id] ?? nextId;
      usedIds.add(id);
      await _plugin.zonedSchedule(
        id: id,
        title: task.title,
        body: task.description.isEmpty ? task.title : task.description,
        scheduledDate: tz.TZDateTime.from(task.dueAt, tz.UTC),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'shiftly_tasks',
            'Task reminders',
            channelDescription: 'Scheduled personal task reminders',
            importance: Importance.max,
            priority: Priority.high,
            icon: 'ic_notification',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: state == TaskReminderPermission.exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: jsonEncode({
          'kind': 'personal-task',
          'ownerId': userId,
          'taskId': task.id,
          'revision': task.revision,
        }),
      );
      if (!existing.containsKey(task.id)) occupied++;
      scheduled.add(task);
    }
    // Approximate native alarms still get server fallback.
    return state == TaskReminderPermission.exact ? scheduled : [];
  }

  @override
  Future<void> clear() async {
    if (!_supported) return;
    await _initialize();
    for (final pending in await _plugin.pendingNotificationRequests()) {
      if (_decode(pending.payload) != null) {
        await _plugin.cancel(id: pending.id);
      }
    }
  }

  @override
  Future<void> cancel(String taskId) async {
    if (!_supported) return;
    await _initialize();
    for (final pending in await _plugin.pendingNotificationRequests()) {
      if (_decode(pending.payload)?['taskId'] == taskId) {
        await _plugin.cancel(id: pending.id);
      }
    }
  }

  @override
  Future<String?> installationId() async =>
      _supported ? _pushStore.installationId() : null;
  @override
  Future<void> close() => opened.close();
}
