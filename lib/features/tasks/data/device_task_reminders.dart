import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/features/breaks/domain/break_notifier.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_preference_store.dart';

import '../domain/personal_task.dart';
import '../domain/task_reminders.dart';
import 'device_break_scheduler.dart';
import 'device_reminder_permissions.dart';
import 'device_task_alarm_reconciler.dart';
import 'device_task_alarm_scheduler.dart';
import 'task_notification_actions.dart';

/// Native pending alarms survive process death and Android reboot.
class DeviceTaskReminders
    implements TaskReminders, BreakNotifier, BreakStartNotifier {
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
    await TaskNotificationSetup.initialize(
      _plugin,
      onTap: (r) {
        final tap = _decodeTap(r.payload);
        if (tap != null) opened.add(tap);
      },
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true &&
        launch?.notificationResponse?.actionId != taskSnoozeAction) {
      initialTap = _decodeTap(launch?.notificationResponse?.payload);
    }
  }

  @override
  Future<void> cancelBreak() async => _supported
      ? _initialize().then((_) => _plugin.cancel(id: 1600000001))
      : null;
  @override
  Future<void> cancelBreakStart() async => _supported
      ? _initialize().then((_) => _plugin.cancel(id: 1600000002))
      : null;
  @override
  Future<bool> scheduleBreakStart(DateTime at, {required bool arabic}) async =>
      _supported &&
      await _initialize().then(
        (_) => scheduleDeviceBreak(_plugin, at, arabic: arabic, start: true),
      );
  @override
  Future<bool> scheduleBreak(DateTime end, {required bool arabic}) async =>
      _supported &&
      await _initialize().then(
        (_) => scheduleDeviceBreak(_plugin, end, arabic: arabic, start: false),
      );
  @override
  Future<TaskReminderPermission> permission(
    String userId, {
    bool request = false,
  }) async => !_supported
      ? TaskReminderPermission.unsupported
      : _initialize().then(
          (_) => resolveDeviceReminderPermission(
            _plugin,
            _preferences,
            userId,
            request: request,
          ),
        );
  @override
  Future<List<PersonalTask>> replace(
    String userId,
    List<PersonalTask> tasks, {
    bool preserveExisting = false,
  }) async => !_supported
      ? []
      : _initialize().then(
          (_) async => replaceDeviceTaskAlarms(
            plugin: _plugin,
            preferences: _preferences,
            userId: userId,
            tasks: tasks,
            state: await permission(userId),
            preserveExisting: preserveExisting,
          ),
        );
  @override
  Future<void> clear() async => _supported
      ? _initialize().then((_) => clearDeviceTaskAlarms(_plugin))
      : null;
  @override
  Future<void> cancel(String taskId) async => _supported
      ? cancelDeviceTaskAlarm(_plugin, _preferences, taskId, _initialize)
      : null;
  Future<void> bindNotificationOwner(String? owner) => owner == null
      ? _preferences.remove(taskNotificationOwnerKey)
      : _preferences.setString(taskNotificationOwnerKey, owner);
  @override
  Future<String?> installationId() async =>
      _supported ? _pushStore.installationId() : null;
  @override
  Future<void> close() => opened.close();
}

Map<String, Object?>? _decodeTap(String? value) {
  try {
    final data = jsonDecode(value ?? '');
    if (data is Map<String, Object?> && data['kind'] == 'foreground-push') {
      return data;
    }
  } on FormatException {
    return null;
  }
  return decodeTaskTapPayload(value);
}
