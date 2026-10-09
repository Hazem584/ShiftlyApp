import 'package:flutter/material.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_detail.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_information_section.dart';

class EmployeeWorkSection extends StatelessWidget {
  const EmployeeWorkSection({super.key, required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context) => EmployeeInformationSection(
    title: 'Work details',
    rows: [
      EmployeeDetail(
        icon: Icons.work_outline_rounded,
        title: 'Employment status',
        value: _employmentLabel(employee.employmentStatus),
      ),
      EmployeeDetail(
        icon: Icons.badge_outlined,
        title: 'Job title',
        value: employee.displayJobTitle,
      ),
      EmployeeDetail(
        icon: Icons.calendar_today_outlined,
        title: 'Joined',
        value: employee.startDate == null
            ? 'Not provided'
            : '${employee.startDate!.day}/${employee.startDate!.month}/${employee.startDate!.year}',
      ),
    ],
  );

  String _employmentLabel(EmploymentStatus status) => switch (status) {
    EmploymentStatus.active => 'Active',
    EmploymentStatus.suspended => 'Suspended',
    EmploymentStatus.onLeave => 'On leave',
    EmploymentStatus.unknown => 'Unknown',
  };
}
