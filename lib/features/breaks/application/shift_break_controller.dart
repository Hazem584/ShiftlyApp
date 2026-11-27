import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/shift_break_state.dart';
import 'shift_break_actions.dart';
import 'shift_break_finish.dart';
import 'shift_break_restore.dart';
import 'shift_break_store.dart';

/// Server attendance records are authoritative; device alarms survive app exit.
class ShiftBreakController extends ShiftBreakStore {
  ShiftBreakController({
    super.preferences,
    super.notifier,
    super.startRemote,
    super.endRemote,
    super.changeRemote,
    super.now,
  });

  Future<void> _queue = Future.value();
  bool _disposed = false;
  final _listeners = <VoidCallback>{};

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

  void bind(String? nextOwner) =>
      bindBreakOwner(this, nextOwner, _changed, _serial);

  void restore(
    String attendanceId, {
    ShiftBreakState? policy,
    bool arabic = false,
  }) {
    if (owner == null) return;
    if (attendance != attendanceId) {
      restoreSavedBreakRecord(this, attendanceId, _serial);
    }
    if (policy != null) {
      restoreBreakPolicy(this, policy, arabic, _changed, _serial);
    }
  }

  Future<bool> start({required bool arabic}) async =>
      owner != null && attendance != null && canStart
      ? executeBreakChange(this, false, arabic, _changed, _serial)
      : false;

  Future<void> end() async {
    if (!busy && running) {
      await executeBreakChange(this, true, false, _changed, _serial);
    }
  }

  Future<void> finishFor(String attendanceId) async {
    if (attendance == attendanceId) await finish();
  }

  Future<void> finish() => finishBreakStore(this, _changed, _serial);

  void dispose() {
    _disposed = true;
    _listeners.clear();
  }
}
