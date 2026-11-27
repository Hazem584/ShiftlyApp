import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';

List<Widget> buildTemplateAttendanceInfo(
  BuildContext context,
  AttendanceRecordApi record,
  String timezone,
) {
  final tz = record.workspaceTimezone ?? timezone;
  return [
    Text(
      record.occurrenceKind == 'EXTRA'
          ? context.tr('Extra shift attendance')
          : record.occurrenceKind == 'BASELINE'
          ? context.tr('BASELINE attendance')
          : context.tr(
              'Historical template attendance; assignment evidence not recorded',
            ),
    ),
    if (record.assignmentId != null)
      Text(
        context.tr('Assignment: {value1}', {
          'value1': (record.assignmentId).toString(),
        }),
      ),
    if (record.extraAuthorizationId != null)
      Text(
        context.tr('Extra authorization: {value1}', {
          'value1': (record.extraAuthorizationId).toString(),
        }),
      ),
    if (record.enteredByMembershipId != null)
      Text(
        context.tr('Entered by membership: {value1}', {
          'value1': (record.enteredByMembershipId).toString(),
        }),
      ),
    if (record.scheduledStartAt != null && record.scheduledEndAt != null)
      Text(
        context.tr('Saved schedule: {value1} to {value2}', {
          'value1': (WorkspaceTime.dateTime(
            record.scheduledStartAt!,
            tz,
          )).toString(),
          'value2': (WorkspaceTime.dateTime(
            record.scheduledEndAt!,
            tz,
          )).toString(),
        }),
      ),
  ];
}
