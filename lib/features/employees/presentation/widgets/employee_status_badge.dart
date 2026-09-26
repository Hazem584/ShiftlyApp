import 'package:flutter/material.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/theme/app_colors.dart';

class EmployeeStatusBadge extends StatelessWidget {
  const EmployeeStatusBadge({required this.status, super.key});
  final EmploymentStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      EmploymentStatus.active => ('Active', AppColors.success),
      EmploymentStatus.suspended => ('Suspended', AppColors.error),
      EmploymentStatus.onLeave => ('On leave', AppColors.warning),
      EmploymentStatus.unknown => ('Unknown', AppColors.textSecondary),
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
