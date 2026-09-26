import 'package:flutter/material.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/widgets/surface_card.dart';

class EmployeeMetricsSection extends StatelessWidget {
  const EmployeeMetricsSection({
    required this.employees,
    this.total,
    super.key,
  });
  final List<Employee> employees;
  final int? total;

  @override
  Widget build(BuildContext context) {
    final active = employees
        .where(
          (employee) => employee.employmentStatus == EmploymentStatus.active,
        )
        .length;
    final suspended = employees
        .where(
          (employee) => employee.employmentStatus == EmploymentStatus.suspended,
        )
        .length;
    return SizedBox(
      height: 86,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        children: [
          _Metric(
            label: 'Total Employees',
            value: total ?? employees.length,
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
            label: 'Loaded suspended',
            value: suspended,
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
