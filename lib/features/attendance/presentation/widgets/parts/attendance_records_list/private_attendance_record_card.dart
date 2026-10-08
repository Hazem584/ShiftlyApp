part of '../../attendance_records_list.dart';

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
                  'In: ${WorkspaceTime.time(record.clockInAt, timezone, locale: Localizations.localeOf(context).toString())}  '
                  'Out: ${WorkspaceTime.time(record.clockOutAt, timezone, locale: Localizations.localeOf(context).toString())}',
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
