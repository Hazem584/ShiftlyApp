import 'dart:async';
import 'dart:convert';

import '../domain/shift_break_state.dart';
import 'shift_break_store.dart';
import 'shift_break_sync.dart';

void restoreSavedBreakRecord(
  ShiftBreakStore s,
  String attendanceId,
  Future<T> Function<T>(Future<T> Function()) serial,
) {
  resetBreakStore(s);
  s.attendance = attendanceId;
  try {
    final raw = s.preferences?.getString(s.storageKey);
    final record = raw == null
        ? null
        : jsonDecode(raw) as Map<String, dynamic>;
    if (record?['attendance'] == attendanceId) {
      if (record?['remoteConfirmed'] == true) {
        applyBreakPolicy(s, ShiftBreakState.fromJson(record!));
      } else {
        s.used = record?['used'] == true;
        s.startedAt = DateTime.tryParse(record?['startedAt'] as String? ?? '');
        s.endedAt = DateTime.tryParse(record?['endedAt'] as String? ?? '');
        s.endsAt = DateTime.tryParse(record?['endsAt'] as String? ?? '');
      }
      s.closed = record?['closed'] == true;
      s.notificationScheduled = record?['notified'] == true;
    } else {
      unawaited(
        serial(() async => s.notifier?.cancelBreak()).catchError((Object _) {}),
      );
    }
  } catch (_) {
    s.error = 'Could not restore the break timer.';
  }
}

void restoreBreakPolicy(
  ShiftBreakStore s,
  ShiftBreakState next,
  bool arabic,
  void Function() notify,
  Future<T> Function<T>(Future<T> Function()) serial,
) {
  if (s.policy == next || isStaleBreakPolicy(s, next)) return;
  applyBreakPolicy(s, next);
  final curOwner = s.owner, curAtt = s.attendance, key = s.storageKey;
  unawaited(
    serial(() async {
      if (curOwner != s.owner || curAtt != s.attendance) return;
      await persistBreakStore(s, key, curAtt!);
      await syncBreakAlarms(s, arabic);
      notify();
    }).catchError((Object _) {}),
  );
}
