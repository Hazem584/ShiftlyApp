import 'package:shiftly/core/utils/clock_time.dart';
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

  static bool isValid(String ianaName) {
    initialize();
    try {
      timezone.getLocation(ianaName);
      return true;
    } on timezone.LocationNotFoundException {
      return false;
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

  static ({DateTime start, DateTime end}) monthUtcRange({
    required int year,
    required int month,
    required String timezoneName,
  }) {
    final zone = location(timezoneName);
    final start = timezone.TZDateTime(zone, year, month);
    final end = timezone.TZDateTime(zone, year, month + 1);
    return (start: start.toUtc(), end: end.toUtc());
  }

  static String dateKey(DateTime utc, String timezoneName) {
    final value = inWorkspace(utc, timezoneName);
    return '${value.year}-${_two(value.month)}-${_two(value.day)}';
  }

  static String localDateKey({
    required int year,
    required int month,
    required int day,
  }) => '$year-${_two(month)}-${_two(day)}';

  static String dateTime(DateTime utc, String ianaName, {String? locale}) {
    final value = inWorkspace(utc, ianaName);
    final month = _two(value.month);
    final day = _two(value.day);
    return '${value.year}-$month-$day ${ClockTime.wallTime(value, locale: locale)} ${value.timeZoneName}';
  }

  static String time(DateTime? utc, String ianaName, {String? locale}) {
    if (utc == null) return 'Not recorded';
    final value = inWorkspace(utc, ianaName);
    return '${ClockTime.wallTime(value, locale: locale)} ${value.timeZoneName}';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
