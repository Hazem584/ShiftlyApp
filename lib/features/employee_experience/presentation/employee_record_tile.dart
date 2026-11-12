import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/work_duration.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

import 'employee_record_screen.dart';
import 'employee_tile.dart';

class EmployeeRecordTile extends StatelessWidget {
  const EmployeeRecordTile({
    required this.record,
    required this.timezone,
    super.key,
  });
  final AttendanceRecordApi record;
  final String timezone;
  @override
  Widget build(BuildContext context) {
    final zone = record.workspaceTimezone ?? timezone;
    final locale = Localizations.localeOf(context).toString();
    return EmployeeTile(
      title:
          '${record.operationalDate ?? WorkspaceTime.dateKey(record.clockInAt, zone)} · ${record.templateName ?? context.tr('Scheduled shift')}',
      subtitle:
          '${WorkspaceTime.time(record.clockInAt, zone, locale: locale)}–${WorkspaceTime.time(record.clockOutAt, zone, locale: locale)} · ${workDuration(record.netWorkedMinutes ?? record.workedMinutes ?? 0, arabic: locale.startsWith('ar'))} · ${context.tr(record.reviewStatus == AttendanceReviewStatus.approved
              ? 'Approved'
              : record.reviewStatus == AttendanceReviewStatus.rejected
              ? 'Rejected'
              : 'Pending review')}',
      icon: record.minutesLate > 0
          ? Icons.schedule_outlined
          : Icons.event_available_outlined,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => EmployeeRecordScreen(record: record, timezone: zone),
        ),
      ),
    );
  }
}
