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
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final headline = Theme.of(context).textTheme.headlineSmall;
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [palette.ink, palette.orange, palette.teal],
              ),
              borderRadius: const BorderRadius.vertical(
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
                  backgroundColor: palette.surface,
                  child: CircleAvatar(
                    radius: 37,
                    backgroundColor: palette.field,
                    foregroundColor: palette.ink,
                    child: Text(employee.initials, style: headline),
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
                    style: headline,
                  ),
                ),
                Text(
                  employee.displayJobTitle,
                  style: TextStyle(color: palette.textSecondary),
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
}
