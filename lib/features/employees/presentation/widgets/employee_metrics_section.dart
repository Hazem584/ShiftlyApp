import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_metrics_section_metric.dart';

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
          EmployeeMetricsSectionMetric(
            label: context.tr('Total Employees'),
            value: total ?? employees.length,
            icon: Icons.groups_outlined,
            color: AppPalette.of(context).ink,
          ),
          const SizedBox(width: 10),
          EmployeeMetricsSectionMetric(
            label: context.tr('Active'),
            value: active,
            icon: Icons.person_rounded,
            color: AppPalette.of(context).success,
          ),
          const SizedBox(width: 10),
          EmployeeMetricsSectionMetric(
            label: context.tr('Loaded suspended'),
            value: suspended,
            icon: Icons.person_off_outlined,
            color: AppPalette.of(context).warning,
          ),
        ],
      ),
    );
  }
}
