import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

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
