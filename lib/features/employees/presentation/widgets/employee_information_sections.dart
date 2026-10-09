import 'package:flutter/material.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_detail.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_information_section.dart';

class EmployeeContactSection extends StatelessWidget {
  const EmployeeContactSection({super.key, required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context) => EmployeeInformationSection(
    title: 'Contact information',
    rows: [
      EmployeeDetail(
        icon: Icons.email_outlined,
        title: 'Email',
        value: employee.displayEmail,
      ),
      EmployeeDetail(
        icon: Icons.phone_outlined,
        title: 'Phone',
        value: employee.displayPhone,
      ),
    ],
  );
}
