import 'workspace_time.dart';

/// An explicit offset selects an instant during a fold. Round-tripping rejects
/// gaps and offsets belonging to the device rather than the workspace.
abstract final class WorkspaceTimestampInput {
  static DateTime parse(String input, String timezone) {
    if (!WorkspaceTime.isValid(timezone))
      { throw const FormatException('Workspace timezone is unavailable.'); }
    final match = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(Z|[+-]\d{2}:\d{2})$',
    ).firstMatch(input.trim());
    if (match == null)
      { throw const FormatException(
        'Use YYYY-MM-DDTHH:mm:ss with Z or an explicit offset such as +03:00.',
      ); }
    final components = [
      for (var i = 1; i <= 6; i++) int.parse(match.group(i)!),
    ];
    final wall = DateTime.utc(
      components[0],
      components[1],
      components[2],
      components[3],
      components[4],
      components[5],
    );
    if (wall.year != components[0] ||
        wall.month != components[1] ||
        wall.day != components[2] ||
        wall.hour != components[3] ||
        wall.minute != components[4] ||
        wall.second != components[5])
      { throw const FormatException('Enter a real calendar date and time.'); }
    final offset = match.group(7)!;
    if (offset != 'Z' &&
        (int.parse(offset.substring(1, 3)) > 23 ||
            int.parse(offset.substring(4)) > 59))
      { throw const FormatException('Invalid UTC offset.'); }
    final instant = DateTime.parse(input.trim()).toUtc();
    final local = WorkspaceTime.inWorkspace(instant, timezone);
    if (local.year != wall.year ||
        local.month != wall.month ||
        local.day != wall.day ||
        local.hour != wall.hour ||
        local.minute != wall.minute ||
        local.second != wall.second)
      { throw FormatException(
        'This time and offset do not exist in $timezone. Check daylight saving time.',
      ); }
    return instant;
  }

  static void validateRange(DateTime start, DateTime end, DateTime now) {
    if (!end.isAfter(start) || start.isAfter(now) || end.isAfter(now))
      { throw const FormatException(
        'Clock-out must follow clock-in; both must be in the past.',
      ); }
  }
}
