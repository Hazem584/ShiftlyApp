import 'dart:async';

import '../domain/break_notifier.dart';
import '../domain/shift_break_state.dart';
import 'shift_break_store.dart';
import 'shift_break_sync.dart';

void bindBreakOwner(
  ShiftBreakStore s,
  String? nextOwner,
  void Function() notify,
  Future<T> Function<T>(Future<T> Function()) serial,
) {
  if (s.owner == nextOwner) return;
  final oldKey = s.owner == null ? null : s.storageKey;
  s.owner = nextOwner;
  s.attendance = null;
  resetBreakStore(s);
  unawaited(
    serial(() async {
      if (oldKey != null) {
        await s.notifier?.cancelBreak();
        if (s.notifier is BreakStartNotifier) {
          await (s.notifier as BreakStartNotifier).cancelBreakStart();
        }
      }
      if (oldKey != null && nextOwner == null) {
        await s.preferences?.remove(oldKey);
      }
    }).catchError((Object _) {}),
  );
  notify();
}

Future<void> finishBreakStore(
  ShiftBreakStore s,
  void Function() notify,
  Future<T> Function<T>(Future<T> Function()) serial,
) async {
  if (s.owner == null || s.attendance == null) return;
  final curOwner = s.owner, curAtt = s.attendance!, key = s.storageKey;
  final consumed = s.takenSeconds;
  s.endedAt ??= s.now();
  if (s.policy?.consumedSeconds != null) {
    s.consumedSeconds = consumed;
    s.policy = ShiftBreakState(
      allowedMinutes: s.allowedMinutes,
      consumedSeconds: consumed,
      plannedMinutes: s.policy?.plannedMinutes,
      lateDeductionMinutes: s.policy?.lateDeductionMinutes ?? 0,
      revision: s.policy?.revision,
      shiftEndsAt: s.policy?.shiftEndsAt,
      startedAt: s.startedAt,
      endedAt: s.endedAt,
    );
  }
  s.closed = true;
  s.endsAt = null;
  notify();
  await serial(() async {
    if (curOwner != s.owner || curAtt != s.attendance) return;
    await syncBreakAlarms(s, false);
    await persistBreakStore(s, key, curAtt);
  });
}
