import 'package:flutter/material.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_list_employee_card.dart';

Widget buildEmployeeListRow(List<Employee> employees, int index, int columns) {
  if (columns == 1) {
    return EmployeeListEmployeeCard(employee: employees[index]);
  }
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: EmployeeListEmployeeCard(employee: employees[index * 2])),
      const SizedBox(width: 16),
      Expanded(
        child: index * 2 + 1 < employees.length
            ? EmployeeListEmployeeCard(employee: employees[index * 2 + 1])
            : const SizedBox.shrink(),
      ),
    ],
  );
}
