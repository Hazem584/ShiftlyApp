import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';
import 'package:shiftly/features/shifts/presentation/utils/shift_card_formatters.dart';
import 'package:shiftly/features/shifts/presentation/widgets/shift_status_badge.dart';

List<Widget> buildEmployeeShiftDetailInfo(
  BuildContext context,
  ShiftRecord record,
  String timezone,
) {
  final locale = Localizations.localeOf(context).toString();
  return [
    Text(
      context.tr('Shift details'),
      style: Theme.of(context).textTheme.headlineSmall,
    ),
    const SizedBox(height: AppSpacing.s),
    ShiftStatusBadge(status: record.status),
    const SizedBox(height: AppSpacing.m),
    Text(
      context.tr('Starts: {value1}', {
        'value1': WorkspaceTime.dateTime(
          record.startsAt,
          timezone,
          locale: locale,
        ),
      }),
    ),
    Text(
      context.tr('Ends: {value1}', {
        'value1': WorkspaceTime.dateTime(
          record.endsAt,
          timezone,
          locale: locale,
        ),
      }),
    ),
    Text(
      context.tr('Break: {value1} minutes', {
        'value1': '${record.breakMinutes}',
      }),
    ),
    if (record.notes != null) ...[
      const SizedBox(height: AppSpacing.s),
      Text(record.notes!),
    ],
    if (record.attendance case final attendance?) ...[
      const SizedBox(height: AppSpacing.m),
      Text(
        context.tr('Clock-in: {value1}', {
          'value1': WorkspaceTime.time(
            attendance.clockInAt,
            timezone,
            locale: locale,
          ),
        }),
      ),
      Text(
        context.tr('Clock-out: {value1}', {
          'value1': WorkspaceTime.time(
            attendance.clockOutAt,
            timezone,
            locale: locale,
          ),
        }),
      ),
      Text(context.tr(attendanceReviewLabel(attendance.reviewStatus))),
    ],
  ];
}
