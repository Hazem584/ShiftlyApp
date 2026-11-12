import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/work_duration.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_day_breakdown.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/correction_request_dialog.dart';

import 'employee_page.dart';
import 'employee_tile.dart';

class EmployeeRecordScreen extends StatelessWidget {
  const EmployeeRecordScreen({
    required this.record,
    required this.timezone,
    super.key,
  });
  final AttendanceRecordApi record;
  final String timezone;
  @override
  Widget build(BuildContext context) {
    final zone = record.workspaceTimezone ?? timezone;
    return EmployeePage(
      title: 'My record',
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (record.clockOutAt != null &&
              record.reviewStatus != AttendanceReviewStatus.rejected)
            FilledButton(
              onPressed: () async {
                final sent = await showCorrectionRequest(context, record, zone);
                if (sent == true && context.mounted) {
                  context.push('/team-work?tab=corrections');
                }
              },
              child: Text(context.tr('Request correction')),
            ),
          TextButton(
            onPressed: () => context.push('/team-work?tab=corrections'),
            child: Text(context.tr('My correction history')),
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            '${context.tr('Operational date')} · ${record.operationalDate ?? WorkspaceTime.dateKey(record.clockInAt, zone)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                label: Text(
                  context.tr(
                    record.reviewStatus == AttendanceReviewStatus.approved
                        ? 'Approved'
                        : record.reviewStatus == AttendanceReviewStatus.rejected
                        ? 'Rejected'
                        : 'Pending review',
                  ),
                ),
              ),
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
      ),
    );
  }
}
