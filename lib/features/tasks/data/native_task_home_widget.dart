import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/personal_task.dart';
import '../domain/task_home_widget.dart';

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
  ) {
    final tasks =
        page.items.where((t) => !t.completed && t.ownerId == ownerId).toList()
          ..sort((a, b) => a.nextDueAt(now).compareTo(b.nextDueAt(now)));
    return {
      'ownerId': ownerId,
      'total': page.total,
      'updatedAt': now.millisecondsSinceEpoch,
      'expiresAt': now.add(const Duration(hours: 24)).millisecondsSinceEpoch,
      'tasks': tasks
          .take(3)
          .map(
            (t) => {
              'id': t.id,
              'title': t.title,
              'dueAt': t.nextDueAt(now).millisecondsSinceEpoch,
              'dueDates': t.scheduledDates
                  .map((d) => d.millisecondsSinceEpoch)
                  .toList(),
              'durationMs': (t.durationMinutes ?? 0) * 60000,
              'endsAt': t
                  .nextDueAt(now)
                  .add(Duration(minutes: t.durationMinutes ?? 0))
                  .millisecondsSinceEpoch,
            },
          )
          .toList(),
    };
  }

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
