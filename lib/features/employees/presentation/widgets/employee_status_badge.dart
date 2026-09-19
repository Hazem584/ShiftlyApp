import 'package:flutter/material.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/theme/app_colors.dart';

class EmployeeStatusBadge extends StatelessWidget {
  const EmployeeStatusBadge({required this.status, super.key});
  final AttendanceStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      AttendanceStatus.present => ('Present', AppColors.success),
      AttendanceStatus.absent => ('Absent', AppColors.error),
      AttendanceStatus.late => ('Late', AppColors.warning),
      AttendanceStatus.notStarted => ('Not started', AppColors.textSecondary),
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
