import 'dart:math' as math;

int attendanceOvertimeMinutes({
  required DateTime clockIn,
  required DateTime clockOut,
  required DateTime? scheduledStart,
  required DateTime? scheduledEnd,
  int unusedBreakSeconds = 0,
}) {
  if (scheduledEnd == null) return 0;
  final lateMilliseconds = scheduledStart == null
      ? 0
      : math.max(0, clockIn.difference(scheduledStart).inMilliseconds);
  final extraMilliseconds =
      clockOut.difference(scheduledEnd).inMilliseconds - lateMilliseconds;
  final postShift = math.max(
    0,
    extraMilliseconds ~/ Duration.millisecondsPerMinute,
  );
  final unusedBreak =
      scheduledStart != null &&
          lateMilliseconds == 0 &&
          !clockOut.isBefore(scheduledEnd)
      ? math.max(0, unusedBreakSeconds ~/ Duration.secondsPerMinute)
      : 0;
  return postShift + unusedBreak;
}
