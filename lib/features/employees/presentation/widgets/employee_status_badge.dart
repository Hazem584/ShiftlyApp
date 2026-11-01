import 'package:flutter/material.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/theme/app_palette.dart';

class EmployeeStatusBadge extends StatelessWidget {
  const EmployeeStatusBadge({required this.status, super.key});
  final EmploymentStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      EmploymentStatus.active => ('Active', AppPalette.of(context).success),
      EmploymentStatus.suspended => ('Suspended', AppPalette.of(context).error),
      EmploymentStatus.onLeave => ('On leave', AppPalette.of(context).warning),
      EmploymentStatus.unknown => (
        'Unknown',
        AppPalette.of(context).textSecondary,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
