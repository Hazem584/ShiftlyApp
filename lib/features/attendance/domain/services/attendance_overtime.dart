import 'dart:math' as math;

int attendanceOvertimeMinutes({
  required DateTime clockIn,
  required DateTime clockOut,
  required DateTime? scheduledStart,
  required DateTime? scheduledEnd,
}) {
  if (scheduledEnd == null) return 0;
  final lateMilliseconds = scheduledStart == null
      ? 0
      : math.max(0, clockIn.difference(scheduledStart).inMilliseconds);
  final extraMilliseconds =
      clockOut.difference(scheduledEnd).inMilliseconds - lateMilliseconds;
  return extraMilliseconds <= 0
      ? 0
      : extraMilliseconds ~/ Duration.millisecondsPerMinute;
}
