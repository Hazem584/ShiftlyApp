import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';

class LeaveStatusBadge extends StatelessWidget {
  const LeaveStatusBadge({required this.status, super.key});
  final LeaveRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, background) = switch (status) {
      LeaveRequestStatus.pending => (
        'Pending',
        AppPalette.of(context).warning,
        AppPalette.of(context).warningSoft,
      ),
      LeaveRequestStatus.approved => (
        'Approved',
        AppPalette.of(context).success,
        AppPalette.of(context).successSoft,
      ),
      LeaveRequestStatus.rejected => (
        'Rejected',
        AppPalette.of(context).error,
        AppPalette.of(context).errorSoft,
      ),
      LeaveRequestStatus.cancelled => (
        'Cancelled',
        AppPalette.of(context).textSecondary,
        AppPalette.of(context).field,
      ),
      LeaveRequestStatus.unknown => (
        'Unknown',
        AppPalette.of(context).textSecondary,
        AppPalette.of(context).field,
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
