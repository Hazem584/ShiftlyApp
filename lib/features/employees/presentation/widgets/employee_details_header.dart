import 'package:flutter/material.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/theme/app_palette.dart';
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppPalette.of(context).ink,
                AppPalette.of(context).orange,
                AppPalette.of(context).teal,
              ],
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
                backgroundColor: AppPalette.of(context).surface,
                child: CircleAvatar(
                  radius: 37,
                  backgroundColor: AppPalette.of(context).field,
                  foregroundColor: AppPalette.of(context).ink,
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
                style: TextStyle(color: AppPalette.of(context).textSecondary),
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
