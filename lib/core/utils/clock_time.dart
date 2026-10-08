import 'dart:async';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Presentation of wall-clock values; never converts zones or durations.
abstract final class ClockTime {
  static bool _initialized = false;

  static String format(int hour, int minute, {String? locale}) {
    if (!_initialized) {
      // The bundled local symbols initialize synchronously; the returned
      // completed future does not perform a platform/network lookup.
      unawaited(initializeDateFormatting());
      _initialized = true;
    }
    final language = Intl.verifiedLocale(
      locale ?? Intl.defaultLocale ?? 'en',
      DateFormat.localeExists,
      onFailure: (_) => 'en',
    );
    final formatted = DateFormat(
      'h:mm a',
      language,
    ).format(DateTime(2000, 1, 1, hour, minute));
    if (language?.split('_').first == 'en') {
      return formatted.replaceAllMapped(
        RegExp(r'\b(am|pm)\b', caseSensitive: false),
        (match) => match[0]!.toUpperCase(),
      );
    }
    return formatted;
  }

  static String minutes(int minuteOfDay, {String? locale}) =>
      format(minuteOfDay ~/ 60, minuteOfDay % 60, locale: locale);

  static String wallTime(DateTime value, {String? locale}) =>
      format(value.hour, value.minute, locale: locale);
}
