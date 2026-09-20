import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/core/widgets/screen_header.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_cubit.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_status_badge.dart';

class EmployeesContent extends StatelessWidget {
  const EmployeesContent({super.key});

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
              _EmployeeMetrics(employees: employees),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('employee-search'),
                      onChanged: (value) =>
                          context.read<EmployeesCubit>().load(query: value),
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded, size: 20),
                        hintText: 'Search employees…',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox.square(
                    dimension: 52,
                    child: OutlinedButton(
                      onPressed: () => ToastService.info(
                        context,
                        message: 'More filters are coming soon',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: AppColors.surface,
                      ),
                      child: const Icon(Icons.tune_rounded, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: switch (state) {
                EmployeesLoading() => const _EmployeesLoading(),
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
                      : RefreshIndicator(
                          color: AppColors.ink,
                          onRefresh: context.read<EmployeesCubit>().load,
                          child: ListView.separated(
                            key: const Key('employee-list'),
                            padding: const EdgeInsets.fromLTRB(18, 2, 18, 30),
                            itemCount: employees.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, index) =>
                                _EmployeeCard(employee: employees[index]),
                          ),
                        ),
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _EmployeeMetrics extends StatelessWidget {
  const _EmployeeMetrics({required this.employees});
  final List<Employee> employees;
  @override
  Widget build(BuildContext context) {
    final active = employees
        .where((e) => e.employmentStatus == EmploymentStatus.active)
        .length;
    final onLeave = employees
        .where((e) => e.employmentStatus == EmploymentStatus.onLeave)
        .length;
    return SizedBox(
      height: 86,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        children: [
          _Metric(
            label: 'Total Employees',
            value: employees.length,
            icon: Icons.groups_outlined,
            color: AppColors.ink,
          ),
          const SizedBox(width: 10),
          _Metric(
            label: 'Active',
            value: active,
            icon: Icons.person_rounded,
            color: AppColors.success,
          ),
          const SizedBox(width: 10),
          _Metric(
            label: 'On Leave',
            value: onLeave,
            icon: Icons.person_off_outlined,
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 145,
    child: SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Text('$value', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
          Icon(icon, color: color, size: 24),
        ],
      ),
    ),
  );
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({required this.employee});
  final Employee employee;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    onTap: () => context.push('/employees/${employee.id}'),
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.field,
          foregroundColor: AppColors.ink,
          child: Text(
            employee.initials,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                employee.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                employee.jobTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_outlined,
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      employee.shift.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            EmployeeStatusBadge(status: employee.attendanceStatus),
            const SizedBox(height: 10),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ],
    ),
  );
}

class _EmployeesLoading extends StatelessWidget {
  const _EmployeesLoading();
  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.symmetric(horizontal: 18),
    itemCount: 4,
    separatorBuilder: (_, _) => const SizedBox(height: 10),
    itemBuilder: (_, _) => Container(
      height: 92,
      decoration: BoxDecoration(
        color: AppColors.field,
        borderRadius: BorderRadius.circular(AppRadii.l),
      ),
    ),
  );
}
