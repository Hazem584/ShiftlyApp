import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_theme.dart';

class AttendanceCalendarSelectedDayEmpty extends StatelessWidget {
  const AttendanceCalendarSelectedDayEmpty({super.key, required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Text(context.tr(message), textAlign: TextAlign.center),
    ),
  );
}
