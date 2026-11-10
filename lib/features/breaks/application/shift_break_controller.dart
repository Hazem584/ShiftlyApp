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
    this.changeRemote,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;
  final SharedPreferences? preferences;
  final BreakNotifier? notifier;
  final Future<ShiftBreakState> Function(String)? startRemote, endRemote;
  final Future<ShiftBreakState> Function(String, bool, int)? changeRemote;
  final DateTime Function() now;
  ShiftBreakState? _policy;
  DateTime? _startedAt, _endedAt;
  int _consumedSeconds = 0;
  bool _closed = false;
  int allowedMinutes = 60;
  String? _owner, _attendance;
  DateTime? endsAt;
  bool used = false, busy = false, notificationScheduled = false;
  String? error;
  Future<void> _queue = Future.value();
  bool _disposed = false;
  final _listeners = <VoidCallback>{};
  DateTime? get reminderAt => _policy?.reminderAt;
  String get _key => 'shiftly.break.$_owner.$_attendance';
  int get totalSeconds => allowedMinutes * 60;
  int get takenSeconds {
    var interval = 0;
    if (_startedAt != null &&
        (_endedAt == null || _policy?.consumedSeconds == null)) {
      var end = _endedAt ?? now();
      final stop = _policy?.shiftEndsAt;
      if (stop != null && stop.isBefore(end)) end = stop;
      interval = end.difference(_startedAt!).inSeconds.clamp(0, totalSeconds);
    }
    return (_consumedSeconds + interval).clamp(0, totalSeconds);
  }

  int get takenMinutes => takenSeconds ~/ 60;
  int get availableSeconds =>
      (totalSeconds - takenSeconds).clamp(0, totalSeconds);
  bool get canStart =>
      !busy &&
      !_closed &&
      !running &&
      availableSeconds > 0 &&
      (_policy?.shiftEndsAt?.isAfter(now()) ?? true) &&
      (!used ||
          _policy?.revision != null ||
          (changeRemote == null && startRemote == null));
  Duration get remaining {
    final value = endsAt?.difference(now()) ?? Duration.zero;
    return value.isNegative ? Duration.zero : value;
  }

  bool get running => remaining > Duration.zero && !_closed;
  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
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

  void _apply(ShiftBreakState policy) {
    _policy = policy;
    allowedMinutes = policy.allowedMinutes;
    _consumedSeconds = policy.consumedSeconds ?? 0;
    _startedAt = policy.startedAt;
    _endedAt = policy.endedAt;
    used = policy.startedAt != null;
    endsAt = policy.endedAt == null ? policy.endsAt : null;
  }

  bool _stale(ShiftBreakState policy) {
    final revision = _policy?.revision;
    if (revision != null) {
      return policy.revision == null || policy.revision! < revision;
    }
    return (_policy?.startedAt != null && policy.startedAt == null) ||
        (_policy?.endedAt != null && policy.endedAt == null);
  }

  void _restorePolicy(ShiftBreakState policy, bool arabic) {
    if (_policy == policy || _stale(policy)) return;
    _apply(policy);
    final owner = _owner, attendance = _attendance, key = _key;
    unawaited(
      _serial(() async {
        if (owner != _owner || attendance != _attendance) return;
        await _persist(key, attendance!);
        await _alarms(arabic);
        _changed();
      }).catchError((Object _) {}),
    );
  }

  Future<void> _alarms(bool arabic) async {
    final notice = notifier;
    if (notice is BreakStartNotifier) {
      await (notice as BreakStartNotifier).cancelBreakStart();
      if (!used && reminderAt?.isAfter(now()) == true && canStart) {
        await (notice as BreakStartNotifier).scheduleBreakStart(
          reminderAt!,
          arabic: arabic,
        );
      }
    }
    notificationScheduled = false;
    if (running) {
      notificationScheduled =
          await notifier?.scheduleBreak(endsAt!, arabic: arabic) ?? false;
    } else {
      await notifier?.cancelBreak();
    }
  }

  Future<void> _persist(String key, String attendance) async {
    final data = {
      'attendance': attendance,
      'used': used,
      'closed': _closed,
      'remoteConfirmed': _policy != null,
      'notified': notificationScheduled,
      'allowedMinutes': allowedMinutes,
      'plannedMinutes': _policy?.plannedMinutes,
      'lateDeductionMinutes': _policy?.lateDeductionMinutes ?? 0,
      'consumedSeconds': _policy?.consumedSeconds,
      'revision': _policy?.revision,
      'shiftEndsAt': _policy?.shiftEndsAt?.toUtc().toIso8601String(),
      'startedAt': _startedAt?.toUtc().toIso8601String(),
      'endedAt': _endedAt?.toUtc().toIso8601String(),
      'endsAt': endsAt?.toUtc().toIso8601String(),
    };
    if (preferences != null &&
        !await preferences!.setString(key, jsonEncode(data))) {
      throw StateError('Unable to persist break');
    }
  }

  void bind(String? owner) {
    if (_owner == owner) return;
    final oldKey = _owner == null ? null : _key;
    _owner = owner;
    _attendance = null;
    _reset();
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

  void _reset() {
    _policy = null;
    _startedAt = _endedAt = endsAt = null;
    _consumedSeconds = 0;
    allowedMinutes = 60;
    used = busy = notificationScheduled = _closed = false;
    error = null;
  }

  void restore(
    String attendanceId, {
    ShiftBreakState? policy,
    bool arabic = false,
  }) {
    if (_owner == null) return;
    if (_attendance != attendanceId) {
      _reset();
      _attendance = attendanceId;
      try {
        final raw = preferences?.getString(_key);
        final record = raw == null
            ? null
            : jsonDecode(raw) as Map<String, dynamic>;
        if (record?['attendance'] == attendanceId) {
          if (record?['remoteConfirmed'] == true) {
            _apply(ShiftBreakState.fromJson(record!));
          } else {
            used = record?['used'] == true;
            _startedAt = DateTime.tryParse(
              record?['startedAt'] as String? ?? '',
            );
            _endedAt = DateTime.tryParse(record?['endedAt'] as String? ?? '');
            endsAt = DateTime.tryParse(record?['endsAt'] as String? ?? '');
          }
          _closed = record?['closed'] == true;
          notificationScheduled = record?['notified'] == true;
        } else {
          unawaited(
            _serial(() async => notifier?.cancelBreak())
                .catchError((Object _) {}),
          );
        }
      } catch (_) {
        error = 'Could not restore the break timer.';
      }
    }
    if (policy != null) _restorePolicy(policy, arabic);
  }

  Future<bool> start({required bool arabic}) async {
    if (_owner == null || _attendance == null || !canStart) return false;
    return _change(false, arabic);
  }

  Future<void> end() async {
    if (!busy && running) await _change(true, false);
  }

  Future<bool> _change(bool end, bool arabic) async {
    final owner = _owner, attendance = _attendance!, key = _key;
    busy = true;
    error = null;
    _changed();
    return _serial(() async {
      try {
        if (owner != _owner || attendance != _attendance) return false;
        final server = changeRemote != null
            ? await changeRemote!(attendance, end, _policy?.revision ?? 0)
            : await (end ? endRemote : startRemote)?.call(attendance);
        if (owner != _owner || attendance != _attendance) return false;
        if (server != null) {
          _apply(server);
        } else {
          final consumed = takenSeconds;
          final started = end ? _startedAt : now();
          _apply(
            ShiftBreakState(
              allowedMinutes: allowedMinutes,
              plannedMinutes: _policy?.plannedMinutes,
              lateDeductionMinutes: _policy?.lateDeductionMinutes ?? 0,
              shiftEndsAt: _policy?.shiftEndsAt,
              consumedSeconds: consumed,
              startedAt: started,
              endedAt: end ? now() : null,
              revision: (_policy?.revision ?? 0) + 1,
            ),
          );
        }
        await _persist(key, attendance);
        _changed();
        try {
          await _alarms(arabic);
        } catch (_) {}
        if (owner != _owner || attendance != _attendance) {
          await notifier?.cancelBreak();
          return false;
        }
        await _persist(key, attendance);
        return true;
      } catch (_) {
        if (owner == _owner) {
          error = 'Could not save the break timer. Try again.';
        }
        return false;
      } finally {
        if (owner == _owner) {
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
    final owner = _owner, attendance = _attendance!, key = _key;
    final consumed = takenSeconds;
    _endedAt ??= now();
    if (_policy?.consumedSeconds != null) {
      _consumedSeconds = consumed;
      _policy = ShiftBreakState(
        allowedMinutes: allowedMinutes,
        consumedSeconds: consumed,
        plannedMinutes: _policy?.plannedMinutes,
        lateDeductionMinutes: _policy?.lateDeductionMinutes ?? 0,
        revision: _policy?.revision,
        shiftEndsAt: _policy?.shiftEndsAt,
        startedAt: _startedAt,
        endedAt: _endedAt,
      );
    }
    _closed = true;
    endsAt = null;
    _changed();
    await _serial(() async {
      if (owner != _owner || attendance != _attendance) return;
      await _alarms(false);
      await _persist(key, attendance);
    });
  }

  void dispose() {
    _disposed = true;
    _listeners.clear();
  }
}
