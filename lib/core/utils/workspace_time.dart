import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

abstract final class WorkspaceTime {
  static bool _initialized = false;

  static void initialize() {
    if (_initialized) return;
    timezone_data.initializeTimeZones();
    _initialized = true;
  }

  static timezone.Location location(String ianaName) {
    initialize();
    try {
      return timezone.getLocation(ianaName);
    } on timezone.LocationNotFoundException {
      return timezone.UTC;
    }
  }

  static timezone.TZDateTime inWorkspace(DateTime utc, String ianaName) =>
      timezone.TZDateTime.from(utc.toUtc(), location(ianaName));

  static DateTime wallTimeToUtc({
    required DateTime date,
    required int hour,
    required int minute,
    required String timezoneName,
  }) => timezone.TZDateTime(
    location(timezoneName),
    date.year,
    date.month,
    date.day,
    hour,
    minute,
  ).toUtc();

  static String dateTime(DateTime utc, String ianaName) {
    final value = inWorkspace(utc, ianaName);
    final month = _two(value.month);
    final day = _two(value.day);
    final hour = _two(value.hour);
    final minute = _two(value.minute);
    return '${value.year}-$month-$day $hour:$minute ${value.timeZoneName}';
  }

  static String time(DateTime? utc, String ianaName) {
    if (utc == null) return 'Not recorded';
    final value = inWorkspace(utc, ianaName);
    return '${_two(value.hour)}:${_two(value.minute)} ${value.timeZoneName}';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
