import 'package:flutter/material.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/widgets/surface_card.dart';

import 'employee_status_badge.dart';

class EmployeeDetailsHeader extends StatelessWidget {
  const EmployeeDetailsHeader({super.key, required this.employee});
  final Employee employee;
  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppPalette.of(context).selected,
          foregroundColor: AppPalette.of(context).primaryColor,
          child: Text(employee.initials),
        ),
        const SizedBox(height: 20),
        Text(
          employee.displayName,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          employee.displayJobTitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        EmployeeStatusBadge(status: employee.employmentStatus),
      ],
    ),
  );
}
