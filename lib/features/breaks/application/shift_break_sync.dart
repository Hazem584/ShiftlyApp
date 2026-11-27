import 'dart:convert';

import '../domain/break_notifier.dart';
import '../domain/shift_break_state.dart';
import 'shift_break_store.dart';

void applyBreakPolicy(ShiftBreakStore s, ShiftBreakState next) {
  s.policy = next;
  s.allowedMinutes = next.allowedMinutes;
  s.consumedSeconds = next.consumedSeconds ?? 0;
  s.startedAt = next.startedAt;
  s.endedAt = next.endedAt;
  s.used = next.startedAt != null;
  s.endsAt = next.endedAt == null ? next.endsAt : null;
}

bool isStaleBreakPolicy(ShiftBreakStore s, ShiftBreakState next) {
  final revision = s.policy?.revision;
  if (revision != null) {
    return next.revision == null || next.revision! < revision;
  }
  return (s.policy?.startedAt != null && next.startedAt == null) ||
      (s.policy?.endedAt != null && next.endedAt == null);
}

void resetBreakStore(ShiftBreakStore s) {
  s.policy = null;
  s.startedAt = s.endedAt = s.endsAt = null;
  s.consumedSeconds = 0;
  s.allowedMinutes = 60;
  s.used = s.busy = s.notificationScheduled = s.closed = false;
  s.error = null;
}

Future<void> syncBreakAlarms(ShiftBreakStore s, bool arabic) async {
  final notice = s.notifier;
  if (notice is BreakStartNotifier) {
    await (notice as BreakStartNotifier).cancelBreakStart();
    if (!s.used && s.reminderAt?.isAfter(s.now()) == true && s.canStart) {
      await (notice as BreakStartNotifier).scheduleBreakStart(
        s.reminderAt!,
        arabic: arabic,
      );
    }
  }
  s.notificationScheduled = false;
  if (s.running) {
    s.notificationScheduled =
        await s.notifier?.scheduleBreak(s.endsAt!, arabic: arabic) ?? false;
  } else {
    await s.notifier?.cancelBreak();
  }
}

Future<void> persistBreakStore(
  ShiftBreakStore s,
  String key,
  String attendance,
) async {
  final data = {
    'attendance': attendance,
    'used': s.used,
    'closed': s.closed,
    'remoteConfirmed': s.policy != null,
    'notified': s.notificationScheduled,
    'allowedMinutes': s.allowedMinutes,
    'plannedMinutes': s.policy?.plannedMinutes,
    'lateDeductionMinutes': s.policy?.lateDeductionMinutes ?? 0,
    'consumedSeconds': s.policy?.consumedSeconds,
    'revision': s.policy?.revision,
    'shiftEndsAt': s.policy?.shiftEndsAt?.toUtc().toIso8601String(),
    'startedAt': s.startedAt?.toUtc().toIso8601String(),
    'endedAt': s.endedAt?.toUtc().toIso8601String(),
    'endsAt': s.endsAt?.toUtc().toIso8601String(),
  };
  if (s.preferences != null &&
      !await s.preferences!.setString(key, jsonEncode(data))) {
    throw StateError('Unable to persist break');
  }
}
