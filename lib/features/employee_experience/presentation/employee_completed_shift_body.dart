import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/work_duration.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/flexible_attendance.dart';

class EmployeeCompletedShiftBody extends StatelessWidget {
  const EmployeeCompletedShiftBody({
    required this.attendance,
    required this.timezone,
    super.key,
  });

  final FlexibleAttendance attendance;
  final String timezone;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.check_circle_outline, size: 64),
      const SizedBox(height: 20),
      Text(
        context.tr('You’re all done.'),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 16),
      Text(
        '${WorkspaceTime.time(attendance.clockInAt, timezone)} → ${WorkspaceTime.time(attendance.clockOutAt, timezone)} · $timezone',
      ),
      Text(
        workDurationWithOvertime(
          attendance.netWorkedMinutes ?? attendance.workedMinutes ?? 0,
          attendance.overtimeMinutes,
          arabic: Localizations.localeOf(context).languageCode == 'ar',
        ),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      Text(
        context.tr(
          attendance.reviewStatus == 'APPROVED' ? 'Approved' : 'Pending review',
        ),
      ),
    ],
  );
}
