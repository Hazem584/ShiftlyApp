import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/attendance/data/attendance_repository.dart';
import 'package:shiftly/features/fixed_shifts/data/fixed_shift_repository.dart';
import 'package:shiftly/features/shifts/data/shift_repository.dart';

class AttendanceRecordsList extends StatelessWidget {
  const AttendanceRecordsList({
    required this.records,
    required this.timezone,
    this.title = 'Recent Attendance',
    this.onTap,
    this.trailing,
    super.key,
  });

  final List<AttendanceRecordApi> records;
  final String timezone;
  final String title;
  final ValueChanged<AttendanceRecordApi>? onTap;
  final Widget Function(AttendanceRecordApi record)? trailing;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.s),
      for (final record in records) ...[
        _AttendanceRecordCard(
          record: record,
          timezone: timezone,
          onTap: onTap == null ? null : () => onTap!(record),
          trailing: trailing?.call(record),
        ),
        const SizedBox(height: 10),
      ],
    ],
  );
}

class _AttendanceRecordCard extends StatelessWidget {
  const _AttendanceRecordCard({
    required this.record,
    required this.timezone,
    this.onTap,
    this.trailing,
  });
  final AttendanceRecordApi record;
  final String timezone;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final date = WorkspaceTime.inWorkspace(
      record.shift?.startsAt ?? record.scheduledStartAt ?? record.clockInAt,
      timezone,
    );
    final (label, color, background) = switch (record.reviewStatus) {
      AttendanceReviewStatus.pending => (
        'Pending review',
        AppColors.warning,
        AppColors.warningSoft,
      ),
      AttendanceReviewStatus.approved => (
        'Approved',
        AppColors.success,
        AppColors.successSoft,
      ),
      AttendanceReviewStatus.rejected => (
        'Rejected',
        AppColors.error,
        const Color(0xFFFFE4E1),
      ),
      AttendanceReviewStatus.unknown => (
        'Unavailable',
        AppColors.textSecondary,
        AppColors.field,
      ),
    };
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                Text(
                  date.day.toString().padLeft(2, '0'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  _month(date.month),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.source == AttendanceSource.template
                      ? record.templateName ?? 'Fixed shift'
                      : record.employee.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  'In: ${WorkspaceTime.time(record.clockInAt, timezone)}  '
                  'Out: ${WorkspaceTime.time(record.clockOutAt, timezone)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  record.isOpen
                      ? 'Open attendance'
                      : '${record.workedMinutes ?? 0} minutes worked',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing ??
              DecoratedBox(
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  String _month(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];
}
