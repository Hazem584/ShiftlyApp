import 'package:flutter/material.dart';
import 'package:shiftly/core/models/employee.dart';

class EmployeeStatusBadge extends StatelessWidget {
  const EmployeeStatusBadge({required this.status, super.key});
  final AttendanceStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      AttendanceStatus.present => ('Present', const Color(0xFF15803D)),
      AttendanceStatus.absent => (
        'Absent',
        Theme.of(context).colorScheme.error,
      ),
      AttendanceStatus.late => ('Late', const Color(0xFFB45309)),
      AttendanceStatus.notStarted => (
        'Not started',
        Theme.of(context).colorScheme.outline,
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
