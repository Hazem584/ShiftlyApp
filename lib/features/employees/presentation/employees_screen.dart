import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/constants/app_strings.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_cubit.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_status_badge.dart';

class EmployeesScreen extends StatelessWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.employees),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Filters',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await context.push<bool>('/employees/add');
          if (added == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Employee added successfully')),
            );
          }
        },
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: TextField(
                key: const Key('employee-search'),
                onChanged: (value) =>
                    context.read<EmployeesCubit>().load(query: value),
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search employees by name',
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<EmployeesCubit, EmployeesState>(
                builder: (context, state) => switch (state) {
                  EmployeesLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  EmployeesError(:final message) => EmptyState(
                    icon: Icons.cloud_off_rounded,
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
                                : Icons.person_search_rounded,
                            title: query.isEmpty
                                ? 'No employees yet'
                                : 'No matching employees',
                            message: query.isEmpty
                                ? 'Add your first team member to get started.'
                                : 'Try another name or clear your search.',
                          )
                        : RefreshIndicator(
                            onRefresh: context.read<EmployeesCubit>().load,
                            child: ListView.separated(
                              key: const Key('employee-list'),
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                0,
                                20,
                                100,
                              ),
                              itemCount: employees.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, index) =>
                                  _EmployeeCard(employee: employees[index]),
                            ),
                          ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({required this.employee});
  final Employee employee;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: () => context.push('/employees/${employee.id}'),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                employee.initials,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.fullName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    employee.jobTitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${employee.shift.name} • ${employee.shift.timeRange}',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                EmployeeStatusBadge(status: employee.attendanceStatus),
                const SizedBox(height: 8),
                const Icon(Icons.chevron_right_rounded, size: 20),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
