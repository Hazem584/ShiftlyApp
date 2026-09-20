import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/core/widgets/screen_header.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_cubit.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_list.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_metrics_section.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_search_bar.dart';
import 'package:shiftly/features/employees/presentation/widgets/employees_loading.dart';

class EmployeesScreen extends StatelessWidget {
  const EmployeesScreen({super.key});

  Future<void> _openAddEmployee(BuildContext context) async {
    final added = await context.push<bool>('/employees/add');
    if (added == true && context.mounted) {
      ToastService.success(context, message: 'Employee added successfully');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: BlocBuilder<EmployeesCubit, EmployeesState>(
        builder: (context, state) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              child: ScreenHeader(
                title: 'Employee Management',
                subtitle: 'Manage your team and their information',
                action: FilledButton.icon(
                  onPressed: () => _openAddEmployee(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(80, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ),
            if (state case EmployeesLoaded(:final employees))
              EmployeeMetricsSection(employees: employees),
            EmployeeSearchBar(
              onChanged: (query) =>
                  context.read<EmployeesCubit>().load(query: query),
            ),
            Expanded(child: _stateBody(context, state)),
          ],
        ),
      ),
    ),
  );

  Widget _stateBody(BuildContext context, EmployeesState state) =>
      switch (state) {
        EmployeesLoading() => const EmployeesLoadingView(),
        EmployeesError(:final message) => EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load employees',
          message: message,
          action: FilledButton(
            onPressed: context.read<EmployeesCubit>().load,
            child: const Text('Retry'),
          ),
        ),
        EmployeesLoaded(:final employees, :final query) =>
          employees.isEmpty
              ? EmptyState(
                  icon: query.isEmpty
                      ? Icons.group_add_outlined
                      : Icons.person_search_outlined,
                  title: query.isEmpty
                      ? 'No employees yet'
                      : 'No matching employees',
                  message: query.isEmpty
                      ? 'Add your first team member to get started.'
                      : 'Try another name or clear your search.',
                )
              : EmployeeList(
                  employees: employees,
                  onRefresh: context.read<EmployeesCubit>().load,
                ),
      };
}
