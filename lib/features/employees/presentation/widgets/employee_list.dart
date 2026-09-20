import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_status_badge.dart';

class EmployeeList extends StatelessWidget {
  const EmployeeList({
    required this.employees,
    required this.onRefresh,
    super.key,
  });
  final List<Employee> employees;
  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    color: AppColors.ink,
    onRefresh: onRefresh,
    child: ListView.separated(
      key: const Key('employee-list'),
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 30),
      itemCount: employees.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) => _EmployeeCard(employee: employees[index]),
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
