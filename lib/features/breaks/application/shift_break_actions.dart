import 'dart:async';

import '../domain/shift_break_state.dart';
import 'shift_break_store.dart';
import 'shift_break_sync.dart';

Future<bool> executeBreakChange(
  ShiftBreakStore s,
  bool end,
  bool arabic,
  void Function() notify,
  Future<T> Function<T>(Future<T> Function()) serial,
) {
  final owner = s.owner, attendance = s.attendance!, key = s.storageKey;
  s.busy = true;
  s.error = null;
  notify();
  return serial(() async {
    try {
      if (owner != s.owner || attendance != s.attendance) return false;
      final server = s.changeRemote != null
          ? await s.changeRemote!(attendance, end, s.policy?.revision ?? 0)
          : await (end ? s.endRemote : s.startRemote)?.call(attendance);
      if (owner != s.owner || attendance != s.attendance) return false;
      applyBreakPolicy(
        s,
        server ??
            ShiftBreakState(
              allowedMinutes: s.allowedMinutes,
              plannedMinutes: s.policy?.plannedMinutes,
              lateDeductionMinutes: s.policy?.lateDeductionMinutes ?? 0,
              shiftEndsAt: s.policy?.shiftEndsAt,
              consumedSeconds: s.takenSeconds,
              startedAt: end ? s.startedAt : s.now(),
              endedAt: end ? s.now() : null,
              revision: (s.policy?.revision ?? 0) + 1,
            ),
      );
      await persistBreakStore(s, key, attendance);
      notify();
      try {
        await syncBreakAlarms(s, arabic);
      } catch (_) {}
      if (owner != s.owner || attendance != s.attendance) {
        await s.notifier?.cancelBreak();
        return false;
      }
      await persistBreakStore(s, key, attendance);
      return true;
    } catch (_) {
      if (owner == s.owner) {
        s.error = 'Could not save the break timer. Try again.';
      }
      return false;
    } finally {
      if (owner == s.owner) {
        s.busy = false;
        notify();
      }
    }
  });
}
