import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';

class LeaveStatusBadge extends StatelessWidget {
  const LeaveStatusBadge({required this.status, super.key});
  final LeaveRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, background) = switch (status) {
      LeaveRequestStatus.pending => (
        'Pending',
        AppColors.warning,
        AppColors.warningSoft,
      ),
      LeaveRequestStatus.approved => (
        'Approved',
        AppColors.success,
        AppColors.successSoft,
      ),
      LeaveRequestStatus.rejected => (
        'Rejected',
        AppColors.error,
        const Color(0xFFFFE5E3),
      ),
      LeaveRequestStatus.cancelled => (
        'Cancelled',
        AppColors.textSecondary,
        const Color(0xFFF1F3F5),
      ),
      LeaveRequestStatus.unknown => (
        'Unknown',
        AppColors.textSecondary,
        const Color(0xFFF1F3F5),
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          context.tr(label),
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
