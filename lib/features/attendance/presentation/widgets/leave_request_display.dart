import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/features/attendance/data/leave_request_repository.dart';

String leaveTypeLabel(LeaveRequestType type) => switch (type) {
  LeaveRequestType.annualLeave => 'Annual leave',
  LeaveRequestType.sickLeave => 'Sick leave',
  LeaveRequestType.emergencyLeave => 'Emergency leave',
  LeaveRequestType.earlyLeave => 'Early departure',
  LeaveRequestType.other => 'Other leave',
  LeaveRequestType.unknown => 'Unknown leave type',
};

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

class LeaveDetailRow extends StatelessWidget {
  const LeaveDetailRow({required this.icon, required this.text, super.key});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 15, color: AppColors.textSecondary),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ),
    ],
  );
}
