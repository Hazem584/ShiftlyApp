import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/break_notifier.dart';

/// A local wellbeing timer. It never changes server attendance or payroll.
class ShiftBreakController {
  ShiftBreakController({
    this.preferences,
    this.notifier,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;
  final SharedPreferences? preferences;
  final BreakNotifier? notifier;
  final DateTime Function() now;
  String? _owner, _attendance;
  DateTime? endsAt;
  bool used = false, busy = false, notificationScheduled = false;
  String? error;
  Future<void> _queue = Future.value();
  bool _disposed = false;
  final _listeners = <VoidCallback>{};
  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
  String get _key => 'shiftly.break.$_owner.$_attendance';
  Duration get remaining {
    final value = endsAt?.difference(now()) ?? Duration.zero;
    return value.isNegative ? Duration.zero : value;
  }

  bool get running => remaining > Duration.zero;
  void _changed() {
    if (!_disposed) {
      for (final listener in List<VoidCallback>.of(_listeners)) {
        listener();
      }
    }
  }

  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.then<void>((_) {}).catchError((Object _) {});
    return result;
  }

  void bind(String? owner) {
    if (_owner == owner) return;
    final oldKey = _owner == null ? null : _key;
    _owner = owner;
    _attendance = null;
    endsAt = null;
    used = false;
    busy = false;
    notificationScheduled = false;
    error = null;
    unawaited(
      _serial(() async {
        if (oldKey != null) await notifier?.cancelBreak();
        if (oldKey != null && owner == null) await preferences?.remove(oldKey);
      }).catchError((Object _) {}),
    );
    _changed();
  }

  void restore(String attendanceId) {
    if (_owner == null || _attendance == attendanceId) return;
    _attendance = attendanceId;
    endsAt = null;
    used = false;
    notificationScheduled = false;
    error = null;
    try {
      final raw = preferences?.getString(_key);
      final record = raw == null
          ? null
          : jsonDecode(raw) as Map<String, dynamic>;
      if (record?['attendance'] == attendanceId) {
        used = record?['used'] == true;
        endsAt = DateTime.tryParse(record?['endsAt'] as String? ?? '');
        notificationScheduled = record?['notified'] == true;
      } else {
        unawaited(
          _serial(() async {
            await notifier?.cancelBreak();
          }).catchError((Object _) {}),
        );
      }
    } catch (_) {
      error = 'Could not restore the break timer.';
    }
  }

  Future<bool> start({required bool arabic}) async {
    if (_owner == null || _attendance == null || used || busy) return false;
    final owner = _owner, attendance = _attendance, key = _key;
    busy = true;
    error = null;
    _changed();
    return _serial(() async {
      try {
        if (_owner != owner || _attendance != attendance) return false;
        final end = now().add(const Duration(hours: 1));
        // Persist before installing the alarm; failure never grants a second break.
        final record = {
          'attendance': attendance,
          'used': true,
          'endsAt': end.toUtc().toIso8601String(),
          'notified': false,
        };
        if (preferences != null &&
            !await preferences!.setString(key, jsonEncode(record))) {
          throw StateError('Unable to persist break');
        }
        used = true;
        endsAt = end;
        _changed();
        bool scheduled = false;
        try {
          scheduled =
              await notifier?.scheduleBreak(end, arabic: arabic) ?? false;
        } catch (_) {}
        if (_owner != owner || _attendance != attendance) {
          await notifier?.cancelBreak();
          return false;
        }
        notificationScheduled = scheduled;
        record['notified'] = scheduled;
        await preferences?.setString(key, jsonEncode(record));
        return true;
      } catch (_) {
        if (_owner == owner) {
          error = 'Could not save the break timer. Try again.';
        }
        return false;
      } finally {
        if (_owner == owner) {
          busy = false;
          _changed();
        }
      }
    });
  }

  Future<void> finishFor(String attendanceId) async {
    if (_attendance == attendanceId) await finish();
  }

  Future<void> finish() async {
    if (_owner == null || _attendance == null) return;
    final owner = _owner, key = _key, attendance = _attendance;
    endsAt = null;
    _changed();
    await _serial(() async {
      if (_owner != owner || _attendance != attendance) return;
      await notifier?.cancelBreak();
      await preferences?.setString(
        key,
        jsonEncode({
          'attendance': attendance,
          'used': used,
          'endsAt': null,
          'notified': false,
        }),
      );
    });
  }

  void dispose() {
    _disposed = true;
    _listeners.clear();
  }
}
