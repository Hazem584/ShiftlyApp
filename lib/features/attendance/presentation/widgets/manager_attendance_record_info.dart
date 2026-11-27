import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/utils/work_duration.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_selfie_viewer.dart';
import 'package:shiftly/features/attendance/presentation/widgets/manager_attendance_template_info.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';

List<Widget> buildManagerAttendanceRecordInfo(
  BuildContext context,
  AttendanceRecordApi record,
  String timezone,
) {
  final locale = Localizations.localeOf(context).toString();
  final tz = record.workspaceTimezone ?? timezone;
  return [
    Text(
      record.employee.displayName,
      style: Theme.of(context).textTheme.headlineSmall,
    ),
    const SizedBox(height: AppSpacing.m),
    Text(
      record.source == AttendanceSource.template
          ? context.tr('Template: {value1} • {value2}', {
              'value1': (record.templateName ?? 'Unavailable').toString(),
              'value2': (record.operationalDate ?? 'Unknown date').toString(),
            })
          : context.tr('Shift: {value1}', {
              'value1':
                  (record.shift == null
                          ? 'Unavailable'
                          : WorkspaceTime.dateTime(
                              record.shift!.startsAt,
                              timezone,
                              locale: locale,
                            ))
                      .toString(),
            }),
    ),
    Text(
      context.tr('Clock-in: {value1}', {
        'value1': (WorkspaceTime.time(
          record.clockInAt,
          tz,
          locale: locale,
        )).toString(),
      }),
    ),
    Text(
      context.tr('Clock-out: {value1}', {
        'value1': (WorkspaceTime.time(
          record.clockOutAt,
          tz,
          locale: locale,
        )).toString(),
      }),
    ),
    if (record.source == AttendanceSource.template)
      ...buildTemplateAttendanceInfo(context, record, timezone),
    Text(
      context.tr('Late: {value1} minutes', {
        'value1': (record.minutesLate).toString(),
      }),
    ),
    if (record.workedMinutes != null)
      Text(
        workDurationWithOvertime(
          record.netWorkedMinutes ?? record.workedMinutes!,
          record.overtimeMinutes,
          arabic: Localizations.localeOf(context).languageCode == 'ar',
        ),
      ),
    if (record.rejectionReason != null) ...[
      const SizedBox(height: AppSpacing.s),
      Text(
        context.tr('Rejection reason: {value1}', {
          'value1': (record.rejectionReason).toString(),
        }),
      ),
    ],
    if (record.hasClockInSelfie)
      AttendanceSelfieViewer(
        workspaceId: record.workspaceId,
        attendanceId: record.id,
      ),
  ];
}
