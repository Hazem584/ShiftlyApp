import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_status_badge.dart';

class EmployeeListEmployeeCard extends StatelessWidget {
  const EmployeeListEmployeeCard({super.key, required this.employee});
  final Employee employee;
  @override
  Widget build(BuildContext context) => SurfaceCard(
    onTap: () => context.push('/employees/${employee.id}'),
    padding: const EdgeInsets.all(16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppPalette.of(context).successSoft,
          foregroundColor: AppPalette.of(context).primaryColor,
          child: Text(
            employee.initials,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                employee.displayName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                employee.displayJobTitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              EmployeeStatusBadge(status: employee.employmentStatus),
            ],
          ),
        ),
      ],
    ),
  );
}
