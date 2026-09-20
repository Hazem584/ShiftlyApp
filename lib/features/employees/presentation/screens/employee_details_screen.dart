import 'package:flutter/material.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_details_content.dart';

class EmployeeDetailsScreen extends StatelessWidget {
  const EmployeeDetailsScreen({required this.employeeId, super.key});

  final String employeeId;

  @override
  Widget build(BuildContext context) =>
      EmployeeDetailsContent(employeeId: employeeId);
}
