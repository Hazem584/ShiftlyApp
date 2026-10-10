import 'package:flutter/widgets.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/clock_time.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/saved_schedule.dart';

String savedScheduleLabel(BuildContext context, SavedSchedule schedule) {
  final start = schedule.fields['startMinute'] as int;
  final end = schedule.fields['endMinute'] as int;
  final locale = Localizations.localeOf(context).toString();
  return context.tr('{name} · {start} – {end}{overnight} · {timezone}', {
    'name': schedule.name,
    'start': ClockTime.minutes(start, locale: locale),
    'end': ClockTime.minutes(end, locale: locale),
    'overnight': end <= start ? context.tr(' (ends next day)') : '',
    'timezone': schedule.timezone,
  });
}
