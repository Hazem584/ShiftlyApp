import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/shifts/data/shift_repository.dart';

class ShiftCard extends StatelessWidget {
  const ShiftCard({
    required this.shift,
    required this.timezone,
    this.onTap,
    this.trailing,
    super.key,
  });

  final ShiftRecord shift;
  final String timezone;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    onTap: onTap,
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.field,
            borderRadius: BorderRadius.circular(AppRadii.m),
          ),
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(Icons.schedule_rounded, size: 22),
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shift.employee.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                WorkspaceTime.dateTime(shift.startsAt, timezone),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                'to ${WorkspaceTime.dateTime(shift.endsAt, timezone)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              ShiftStatusBadge(status: shift.status),
            ],
          ),
        ),
        if (trailing != null) trailing! else const Icon(Icons.chevron_right),
      ],
    ),
  );
}

class ShiftStatusBadge extends StatelessWidget {
  const ShiftStatusBadge({required this.status, super.key});
  final ShiftStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, background) = switch (status) {
      ShiftStatus.scheduled => ('Scheduled', AppColors.ink, AppColors.selected),
      ShiftStatus.completed => (
        'Completed',
        AppColors.success,
        AppColors.successSoft,
      ),
      ShiftStatus.cancelled => (
        'Cancelled',
        AppColors.error,
        const Color(0xFFFFE4E1),
      ),
      ShiftStatus.unknown => (
        'Unavailable',
        AppColors.textSecondary,
        AppColors.field,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

String attendanceReviewLabel(AttendanceReviewStatus status) => switch (status) {
  AttendanceReviewStatus.pending => 'Pending review',
  AttendanceReviewStatus.approved => 'Approved',
  AttendanceReviewStatus.rejected => 'Rejected',
  AttendanceReviewStatus.unknown => 'Unavailable',
};
