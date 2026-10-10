import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

class ShiftStatusBadge extends StatelessWidget {
  const ShiftStatusBadge({required this.status, super.key});
  final ShiftStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, background) = switch (status) {
      ShiftStatus.scheduled => (
        'Scheduled',
        AppPalette.of(context).ink,
        AppPalette.of(context).selected,
      ),
      ShiftStatus.completed => (
        'Completed',
        AppPalette.of(context).success,
        AppPalette.of(context).successSoft,
      ),
      ShiftStatus.cancelled => (
        'Cancelled',
        AppPalette.of(context).error,
        AppPalette.of(context).errorSoft,
      ),
      ShiftStatus.unknown => (
        'Unavailable',
        AppPalette.of(context).textSecondary,
        AppPalette.of(context).field,
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
