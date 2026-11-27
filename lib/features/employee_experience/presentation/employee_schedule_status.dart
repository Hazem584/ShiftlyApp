import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/features/attendance/presentation/cubit/attendance_calendar_cubit.dart';

List<Widget> employeeScheduleStatus(
  BuildContext context,
  AttendanceCalendarState calendar, {
  required VoidCallback onRetry,
}) => [
  if (calendar.loading && calendar.data == null) const AppContentLoading(),
  if (calendar.failure != null) ...[
    Text(
      calendar.failure!.message,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
    TextButton(onPressed: onRetry, child: Text(context.tr('Retry'))),
  ],
];
