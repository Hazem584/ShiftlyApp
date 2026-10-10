import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
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
                  context.tr(_month(date.month)),
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
                      ? record.templateName ?? context.tr('Fixed shift')
                      : record.employee.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (record.source == AttendanceSource.template)
                  Text(
                    record.occurrenceKind == 'EXTRA'
                        ? context.tr('EXTRA (optional; no automatic BLUE)')
                        : record.occurrenceKind == 'BASELINE'
                        ? context.tr('BASELINE')
                        : context.tr(
                            'Historical template attendance; assignment evidence not recorded',
                          ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (record.source == AttendanceSource.template)
                  Text(
                    context.tr('Operational date: {value1} / {value2}', {
                      'value1':
                          (record.operationalDate?.split('T').first ??
                                  'Not recorded')
                              .toString(),
                      'value2': (savedTimezone).toString(),
                    }),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: 3),
                Text(
                  context.tr('In: {value1}  Out: {value2}', {
                    'value1': (WorkspaceTime.time(
                      record.clockInAt,
                      savedTimezone,
                      locale: Localizations.localeOf(context).toString(),
                    )).toString(),
                    'value2': (WorkspaceTime.time(
                      record.clockOutAt,
                      savedTimezone,
                      locale: Localizations.localeOf(context).toString(),
                    )).toString(),
                  }),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  record.isOpen
                      ? context.tr('Open attendance')
                      : record.reviewStatus ==
                                AttendanceReviewStatus.rejected &&
                            record.clockOutAt == null
                      ? context.tr('Rejected; occurrence remains used')
                      : record.workedMinutes == null
                      ? context.tr('Duration not recorded')
                      : context.tr('{value1} minutes worked', {
                          'value1': (record.workedMinutes).toString(),
                        }),
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
                    context.tr(label),
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
