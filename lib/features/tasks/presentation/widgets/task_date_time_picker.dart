import 'package:day_night_time_picker/day_night_time_picker.dart'
    as clock_picker;
import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

Future<DateTime?> pickTaskCalendarDate(BuildContext context, DateTime initial) {
  final now = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: initial.isBefore(now) ? now : initial,
    firstDate: DateTime(now.year, now.month, now.day),
    lastDate: DateTime(now.year + 100, 12, 31),
  );
}

Future<DateTime?> pickTaskClockTime(
  BuildContext context,
  DateTime baseDate, {
  DateTime? initialTime,
  bool includeUnitLabels = false,
}) async {
  FocusScope.of(context).unfocus();
  final seed = initialTime ?? baseDate;
  clock_picker.Time? chosen;
  await Navigator.of(context).push(
    clock_picker.showPicker(
      context: context,
      value: clock_picker.Time(hour: seed.hour, minute: seed.minute),
      onChange: (time) => chosen = time,
      is24HrFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      accentColor: Theme.of(context).colorScheme.primary,
      themeData: Theme.of(context),
      backgroundColor: Theme.of(context).colorScheme.surface,
      ltrMode: Directionality.of(context) == TextDirection.ltr,
      amLabel: MaterialLocalizations.of(context).anteMeridiemAbbreviation,
      pmLabel: MaterialLocalizations.of(context).postMeridiemAbbreviation,
      width: (MediaQuery.sizeOf(context).width - 48).clamp(240.0, 380.0),
      borderRadius: 24,
      dialogInsetPadding: const EdgeInsets.all(16),
      cancelText: context.tr('Cancel'),
      okText: context.tr('Confirm time'),
      hourLabel: includeUnitLabels ? context.tr('Hours') : 'hours',
      minuteLabel: includeUnitLabels ? context.tr('Minutes') : 'minutes',
    ),
  );
  final time = chosen;
  if (!context.mounted || time == null) return null;
  return DateTime(
    baseDate.year,
    baseDate.month,
    baseDate.day,
    time.hour,
    time.minute,
  );
}
