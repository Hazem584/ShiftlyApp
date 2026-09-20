import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/features/employees/data/employee_repository.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_details_header.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_details_loading.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_information_sections.dart';

class EmployeeDetailsScreen extends StatelessWidget {
  const EmployeeDetailsScreen({required this.employeeId, super.key});

  final String employeeId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Employee details')),
    body: FutureBuilder<Employee?>(
      future: context.read<EmployeeRepository>().getEmployee(employeeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const EmployeeDetailsLoading();
        }
        final employee = snapshot.data;
        if (employee == null) {
          return const EmptyState(
            icon: Icons.person_search_outlined,
            title: 'Employee not found',
            message: 'This employee may no longer be available.',
          );
        }
        return ListView(
          key: const Key('employee-details-content'),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
          children: [
            EmployeeDetailsHeader(employee: employee),
            const SizedBox(height: AppSpacing.l),
            EmployeeContactSection(employee: employee),
            const SizedBox(height: AppSpacing.l),
            EmployeeWorkSection(employee: employee),
          ],
        );
      },
    ),
  );
}
