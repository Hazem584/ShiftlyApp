import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/personal_task.dart';
import '../domain/task_home_widget.dart';
import 'task_widget_snapshot.dart';

/// Shares only a small display snapshot. Never shares authentication tokens.
class NativeTaskHomeWidget implements TaskHomeWidget {
  static const channel = MethodChannel('shiftly/task_widget');
  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Map<String, Object?> snapshot(
    String ownerId,
    TaskPage page,
    DateTime now,
  ) => buildTaskWidgetSnapshot(ownerId, page, now);

  @override
  Future<void> publish(String ownerId, TaskPage page, DateTime now) async {
    if (!supported) return;
    await channel.invokeMethod<void>(
      'publish',
      jsonEncode(snapshot(ownerId, page, now)),
    );
  }

  @override
  Future<void> clear() async {
    if (supported) await channel.invokeMethod<void>('clear');
  }

  @override
  bool get isSupported => supported;

  @override
  Future<bool> requestPin() async {
    if (!supported) return false;
    try {
      return await channel.invokeMethod<bool>('pin') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
