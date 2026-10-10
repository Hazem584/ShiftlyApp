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
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppPalette.of(context).orangeSoft,
          foregroundColor: AppPalette.of(context).orange,
          child: Text(
            employee.initials,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                employee.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                employee.displayJobTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppPalette.of(context).textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(
                    Icons.mail_outline_rounded,
                    size: 13,
                    color: AppPalette.of(context).textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      employee.displayEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppPalette.of(context).textSecondary,
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
            EmployeeStatusBadge(status: employee.employmentStatus),
            const SizedBox(height: 10),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppPalette.of(context).textSecondary,
            ),
          ],
        ),
      ],
    ),
  );
}
