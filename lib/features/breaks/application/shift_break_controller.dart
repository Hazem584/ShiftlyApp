import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/break_notifier.dart';
import '../domain/shift_break_state.dart';

/// Server attendance records are authoritative; device alarms survive app exit.
class ShiftBreakController {
  ShiftBreakController({
    this.preferences,
    this.notifier,
    this.startRemote,
    this.endRemote,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;
  final SharedPreferences? preferences;
  final BreakNotifier? notifier;
  final Future<ShiftBreakState> Function(String)? startRemote, endRemote;
  ShiftBreakState? _policy;
  DateTime? _startedAt, _endedAt;
  int allowedMinutes = 60;
  DateTime? get reminderAt => _policy?.reminderAt;
  int get takenMinutes {
    if (_startedAt == null) return 0;
    return ((_endedAt ?? now()).difference(_startedAt!).inMinutes).clamp(
      0,
      allowedMinutes,
    );
  }

  int get totalSeconds => allowedMinutes * 60;
  Future<void> end() async {
    if (busy || !running) return;
    if (endRemote == null) {
      await finish();
      return;
    }
    final owner = _owner, attendance = _attendance;
    busy = true;
    error = null;
    _changed();
    try {
      final result = await endRemote!(attendance!);
      if (owner != _owner || attendance != _attendance) return;
      _endedAt = result.endedAt;
      _policy = result;
      await finish();
    } catch (_) {
      if (owner == _owner) error = 'Could not save the break timer. Try again.';
    } finally {
      if (owner == _owner) {
        busy = false;
        _changed();
      }
    }
  }

  void _restorePolicy(ShiftBreakState policy, bool arabic) {
    if (_policy == policy) return;
    // A widget can still hold the pre-mutation attendance response until refresh.
    if (_policy?.startedAt != null && policy.startedAt == null) return;
    if (_policy?.endedAt != null && policy.endedAt == null) return;
    _policy = policy;
    allowedMinutes = policy.allowedMinutes;
    used = policy.startedAt != null;
    _startedAt = policy.startedAt;
    _endedAt = policy.endedAt;
    endsAt = policy.endsAt;
    final owner = _owner, attendance = _attendance;
    unawaited(
      _serial(() async {
        if (owner != _owner || attendance != _attendance) return;
        final notice = notifier;
        if (notice is BreakStartNotifier) {
          await (notice as BreakStartNotifier).cancelBreakStart();
          if (!used &&
              policy.reminderAt?.isAfter(now()) == true &&
              allowedMinutes > 0) {
            await (notice as BreakStartNotifier).scheduleBreakStart(
              policy.reminderAt!,
              arabic: arabic,
            );
          }
        }
        if (running) {
          notificationScheduled =
              await notifier?.scheduleBreak(endsAt!, arabic: arabic) ?? false;
        } else {
          await notifier?.cancelBreak();
        }
        _changed();
      }).catchError((Object _) {}),
    );
  }

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
    _policy = null;
    _startedAt = null;
    _endedAt = null;
    allowedMinutes = 60;
    endsAt = null;
    used = false;
    busy = false;
    notificationScheduled = false;
    error = null;
    unawaited(
      _serial(() async {
        if (oldKey != null) {
          await notifier?.cancelBreak();
          final notice = notifier;
          if (notice is BreakStartNotifier) {
            await (notice as BreakStartNotifier).cancelBreakStart();
          }
        }
        if (oldKey != null && owner == null) await preferences?.remove(oldKey);
      }).catchError((Object _) {}),
    );
    _changed();
  }

  void restore(
    String attendanceId, {
    ShiftBreakState? policy,
    bool arabic = false,
  }) {
    if (_owner == null) return;
    if (_attendance == attendanceId) {
      if (policy != null) _restorePolicy(policy, arabic);
      return;
    }
    _policy = null;
    _startedAt = null;
    _endedAt = null;
    allowedMinutes = 60;
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
        if (record?['remoteConfirmed'] == true) {
          _startedAt = DateTime.tryParse(record?['startedAt'] as String? ?? '');
          _endedAt = DateTime.tryParse(record?['endedAt'] as String? ?? '');
          allowedMinutes = (record?['allowedMinutes'] as int? ?? 60).clamp(
            0,
            1440,
          );
          _policy = ShiftBreakState(
            allowedMinutes: allowedMinutes,
            plannedMinutes: record?['plannedMinutes'] as int?,
            lateDeductionMinutes: record?['lateDeductionMinutes'] as int? ?? 0,
            startedAt: _startedAt,
            endedAt: _endedAt,
          );
        }
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
    if (policy != null) _restorePolicy(policy, arabic);
  }

  Future<bool> start({required bool arabic}) async {
    if (_owner == null ||
        _attendance == null ||
        used ||
        busy ||
        allowedMinutes <= 0) {
      return false;
    }
    final owner = _owner, attendance = _attendance, key = _key;
    busy = true;
    error = null;
    _changed();
    return _serial(() async {
      try {
        if (_owner != owner || _attendance != attendance) return false;
        final server = await startRemote?.call(attendance!);
        if (_owner != owner || _attendance != attendance) return false;
        final end =
            server?.endsAt ?? now().add(Duration(minutes: allowedMinutes));
        _startedAt = server?.startedAt ?? now();
        _endedAt = server?.endedAt;
        if (server != null) {
          _policy = server;
          allowedMinutes = server.allowedMinutes;
        }
        final notice = notifier;
        if (notice is BreakStartNotifier) {
          await (notice as BreakStartNotifier).cancelBreakStart();
        }
        // Persist before installing the alarm; failure never grants a second break.
        final record = {
          'attendance': attendance,
          'used': true,
          'endsAt': end.toUtc().toIso8601String(),
          'notified': false,
          'remoteConfirmed': server != null,
          'plannedMinutes': server?.plannedMinutes,
          'lateDeductionMinutes': server?.lateDeductionMinutes ?? 0,
          'allowedMinutes': allowedMinutes,
          'startedAt': _startedAt?.toUtc().toIso8601String(),
          'endedAt': _endedAt?.toUtc().toIso8601String(),
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
    _endedAt ??= now();
    endsAt = null;
    _changed();
    await _serial(() async {
      if (_owner != owner || _attendance != attendance) return;
      await notifier?.cancelBreak();
      final notice = notifier;
      if (notice is BreakStartNotifier) {
        await (notice as BreakStartNotifier).cancelBreakStart();
      }
      await preferences?.setString(
        key,
        jsonEncode({
          'attendance': attendance,
          'used': used,
          'remoteConfirmed': _policy?.startedAt != null,
          'plannedMinutes': _policy?.plannedMinutes,
          'lateDeductionMinutes': _policy?.lateDeductionMinutes ?? 0,
          'allowedMinutes': allowedMinutes,
          'startedAt': _startedAt?.toUtc().toIso8601String(),
          'endedAt': _endedAt?.toUtc().toIso8601String(),
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
