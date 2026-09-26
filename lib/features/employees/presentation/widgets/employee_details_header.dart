import 'package:flutter/material.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_status_badge.dart';

class EmployeeDetailsHeader extends StatelessWidget {
  const EmployeeDetailsHeader({super.key, required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        Container(
          height: 88,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.ink, AppColors.orange, AppColors.teal],
            ),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadii.l),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -36),
          child: Column(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: AppColors.surface,
                child: CircleAvatar(
                  radius: 37,
                  backgroundColor: AppColors.field,
                  foregroundColor: AppColors.ink,
                  child: Text(
                    employee.initials,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  employee.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Text(
                employee.displayJobTitle,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              EmployeeStatusBadge(status: employee.employmentStatus),
            ],
          ),
        ),
      ],
    ),
  );
}
