import 'package:shiftly/core/utils/workspace_time.dart';

/// Return real instants for a wall time: none in a DST gap, two in a fold.
List<DateTime> attendanceReviewInstants(
  DateTime date,
  int hour,
  int minute,
  String timezone,
) {
  final zoneName = timezone == 'UTC' ? 'Etc/UTC' : timezone;
  if (!WorkspaceTime.isValid(zoneName)) return const [];
  final wall = DateTime.utc(date.year, date.month, date.day, hour, minute);
  final offsets = <int>{
    WorkspaceTime.inWorkspace(wall, zoneName).timeZoneOffset.inMilliseconds,
    ...WorkspaceTime.location(zoneName).zones
        .map((zone) => zone.offset.inMilliseconds),
  };
  final instants = <DateTime>[];
  for (final offset in offsets) {
    final instant = DateTime.fromMillisecondsSinceEpoch(
      wall.millisecondsSinceEpoch - offset,
      isUtc: true,
    );
    final local = WorkspaceTime.inWorkspace(instant, zoneName);
    if (local.year == date.year &&
        local.month == date.month &&
        local.day == date.day &&
        local.hour == hour &&
        local.minute == minute) {
      instants.add(instant);
    }
  }
  return instants..sort();
}
