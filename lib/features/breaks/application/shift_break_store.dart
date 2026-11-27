import 'package:shared_preferences/shared_preferences.dart';

import '../domain/break_notifier.dart';
import '../domain/shift_break_state.dart';

abstract class ShiftBreakStore {
  ShiftBreakStore({
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

  ShiftBreakState? policy;
  DateTime? startedAt, endedAt;
  int consumedSeconds = 0;
  bool closed = false;
  int allowedMinutes = 60;
  String? owner, attendance;
  DateTime? endsAt;
  bool used = false, busy = false, notificationScheduled = false;
  String? error;

  DateTime? get reminderAt => policy?.reminderAt;
  String get storageKey => 'shiftly.break.$owner.$attendance';
  int get totalSeconds => allowedMinutes * 60;
  int get takenSeconds {
    var interval = 0;
    if (startedAt != null &&
        (endedAt == null || policy?.consumedSeconds == null)) {
      var end = endedAt ?? now();
      final stop = policy?.shiftEndsAt;
      if (stop != null && stop.isBefore(end)) end = stop;
      interval = end.difference(startedAt!).inSeconds.clamp(0, totalSeconds);
    }
    return (consumedSeconds + interval).clamp(0, totalSeconds);
  }

  int get takenMinutes => takenSeconds ~/ 60;
  int get availableSeconds =>
      (totalSeconds - takenSeconds).clamp(0, totalSeconds);
  bool get canStart =>
      !busy &&
      !closed &&
      !running &&
      availableSeconds > 0 &&
      (policy?.shiftEndsAt?.isAfter(now()) ?? true) &&
      (!used ||
          policy?.revision != null ||
          (changeRemote == null && startRemote == null));
  Duration get remaining {
    final value = endsAt?.difference(now()) ?? Duration.zero;
    return value.isNegative ? Duration.zero : value;
  }

  bool get running => remaining > Duration.zero && !closed;
}
