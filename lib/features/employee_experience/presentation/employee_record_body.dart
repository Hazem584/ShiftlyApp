import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/work_duration.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_day_breakdown.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

import 'employee_tile.dart';

class EmployeeRecordBody extends StatelessWidget {
  const EmployeeRecordBody({
    required this.record,
    required this.zone,
    super.key,
  });

  final AttendanceRecordApi record;
  final String zone;

  @override
  Widget build(BuildContext context) {
    final opDate =
        record.operationalDate ?? WorkspaceTime.dateKey(record.clockInAt, zone);
    final reviewLabel = switch (record.reviewStatus) {
      AttendanceReviewStatus.approved => 'Approved',
      AttendanceReviewStatus.rejected => 'Rejected',
      _ => 'Pending review',
    };
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          '${context.tr('Operational date')} · $opDate',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text(context.tr(reviewLabel))),
            Chip(
              label: Text(
                context.tr(record.minutesLate > 0 ? 'Late' : 'On time'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          record.templateName ?? context.tr('Scheduled shift'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          '${context.tr('Scheduled')} ${WorkspaceTime.time(record.scheduledStartAt, zone)}–${WorkspaceTime.time(record.scheduledEndAt, zone)} · $zone',
        ),
        const SizedBox(height: 24),
        EmployeeTile(
          title:
              '${WorkspaceTime.time(record.clockInAt, zone)} → ${WorkspaceTime.time(record.clockOutAt, zone)}',
          subtitle: workDurationWithOvertime(
            record.netWorkedMinutes ?? record.workedMinutes ?? 0,
            record.overtimeMinutes,
            arabic: Localizations.localeOf(context).languageCode == 'ar',
          ),
        ),
        const SizedBox(height: 20),
        EmployeeTile(
          title: context.tr('Recorded times look wrong?'),
          subtitle: context.tr('Request a correction for manager review.'),
          icon: Icons.edit_calendar_outlined,
        ),
        const SizedBox(height: 20),
        AttendanceDayBreakdown(record: record),
        if (record.rejectionReason != null) Text(record.rejectionReason!),
      ],
    );
  }
}
