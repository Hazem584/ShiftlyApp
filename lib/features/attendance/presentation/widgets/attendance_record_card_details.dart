import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/utils/work_duration.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

String attendanceMonthAbbrev(int month) => const [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
][month - 1];

(String, Color, Color) attendanceReviewStatusStyle(
  BuildContext context,
  AttendanceReviewStatus status,
) => switch (status) {
  AttendanceReviewStatus.pending => (
    'Pending review',
    AppPalette.of(context).warning,
    AppPalette.of(context).warningSoft,
  ),
  AttendanceReviewStatus.approved => (
    'Approved',
    AppPalette.of(context).success,
    AppPalette.of(context).successSoft,
  ),
  AttendanceReviewStatus.rejected => (
    'Rejected',
    AppPalette.of(context).error,
    AppPalette.of(context).errorSoft,
  ),
  AttendanceReviewStatus.unknown => (
    'Unavailable',
    AppPalette.of(context).textSecondary,
    AppPalette.of(context).field,
  ),
};

Widget buildAttendanceRecordDetailsColumn(
  BuildContext context,
  AttendanceRecordApi record,
  String savedTimezone,
) {
  final locale = Localizations.localeOf(context).toString();
  final secondary = TextStyle(
    color: AppPalette.of(context).textSecondary,
    fontSize: 11,
  );
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        record.source == AttendanceSource.template
            ? record.templateName ?? context.tr('Fixed shift')
            : record.employee.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      if (record.source == AttendanceSource.template) ...[
        Text(
          record.occurrenceKind == 'EXTRA'
              ? context.tr('Extra shift')
              : record.occurrenceKind == 'BASELINE'
              ? context.tr('BASELINE')
              : context.tr(
                  'Historical template attendance; assignment evidence not recorded',
                ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          context.tr('Operational date: {value1} / {value2}', {
            'value1':
                (record.operationalDate?.split('T').first ?? 'Not recorded')
                    .toString(),
            'value2': savedTimezone,
          }),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
      const SizedBox(height: 3),
      Text(
        context.tr('In: {value1}  Out: {value2}', {
          'value1': WorkspaceTime.time(
            record.clockInAt,
            savedTimezone,
            locale: locale,
          ),
          'value2': WorkspaceTime.time(
            record.clockOutAt,
            savedTimezone,
            locale: locale,
          ),
        }),
        style: secondary,
      ),
      Text(_durationText(context, record), style: secondary),
    ],
  );
}

String _durationText(BuildContext context, AttendanceRecordApi record) {
  if (record.isOpen) return context.tr('Open attendance');
  if (record.reviewStatus == AttendanceReviewStatus.rejected &&
      record.clockOutAt == null) {
    return context.tr('Rejected; occurrence remains used');
  }
  if (record.workedMinutes == null) return context.tr('Duration not recorded');
  return workDurationWithOvertime(
    record.netWorkedMinutes ?? record.workedMinutes!,
    record.overtimeMinutes,
    arabic: Localizations.localeOf(context).languageCode == 'ar',
  );
}
