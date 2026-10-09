import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

class AttendanceRecordCard extends StatelessWidget {
  const AttendanceRecordCard({
    super.key,
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
    final savedTimezone = record.workspaceTimezone ?? timezone;
    final date = WorkspaceTime.inWorkspace(
      record.shift?.startsAt ?? record.scheduledStartAt ?? record.clockInAt,
      savedTimezone,
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
                if (record.source == AttendanceSource.template)
                  Text(
                    record.occurrenceKind == 'EXTRA'
                        ? 'EXTRA (optional; no automatic BLUE)'
                        : record.occurrenceKind == 'BASELINE'
                        ? 'BASELINE'
                        : 'Historical template attendance; assignment evidence not recorded',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (record.source == AttendanceSource.template)
                  Text(
                    'Operational date: ${record.operationalDate?.split('T').first ?? 'Not recorded'} / $savedTimezone',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: 3),
                Text(
                  'In: ${WorkspaceTime.time(record.clockInAt, savedTimezone, locale: Localizations.localeOf(context).toString())}  '
                  'Out: ${WorkspaceTime.time(record.clockOutAt, savedTimezone, locale: Localizations.localeOf(context).toString())}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  record.isOpen
                      ? 'Open attendance'
                      : record.reviewStatus ==
                                AttendanceReviewStatus.rejected &&
                            record.clockOutAt == null
                      ? 'Rejected; occurrence remains used'
                      : record.workedMinutes == null
                      ? 'Duration not recorded'
                      : '${record.workedMinutes} minutes worked',
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
