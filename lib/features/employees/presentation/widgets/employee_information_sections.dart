import 'package:flutter/material.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/surface_card.dart';

class EmployeeContactSection extends StatelessWidget {
  const EmployeeContactSection({super.key, required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context) => _InformationSection(
    title: 'Contact information',
    rows: [
      _Detail(
        icon: Icons.email_outlined,
        title: 'Email',
        value: employee.email,
      ),
      _Detail(
        icon: Icons.phone_outlined,
        title: 'Phone',
        value: employee.phone,
      ),
    ],
  );
}

class EmployeeWorkSection extends StatelessWidget {
  const EmployeeWorkSection({super.key, required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context) => _InformationSection(
    title: 'Work details',
    rows: [
      _Detail(
        icon: Icons.work_outline_rounded,
        title: 'Employment status',
        value: _employmentLabel(employee.employmentStatus),
      ),
      _Detail(
        icon: Icons.location_on_outlined,
        title: 'Workplace',
        value: employee.location.name,
      ),
      _Detail(
        icon: Icons.schedule_outlined,
        title: 'Assigned shift',
        value: '${employee.shift.name}\n${employee.shift.timeRange}',
      ),
      _Detail(
        icon: Icons.calendar_today_outlined,
        title: 'Start date',
        value:
            '${employee.startDate.day}/${employee.startDate.month}/${employee.startDate.year}',
      ),
    ],
  );

  String _employmentLabel(EmploymentStatus status) => switch (status) {
    EmploymentStatus.active => 'Active',
    EmploymentStatus.onLeave => 'On leave',
    EmploymentStatus.inactive => 'Inactive',
  };
}

class _InformationSection extends StatelessWidget {
  const _InformationSection({required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.s),
      SurfaceCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var index = 0; index < rows.length; index++) ...[
              if (index > 0)
                const Divider(height: 1, indent: 58, endIndent: 14),
              rows[index],
            ],
          ],
        ),
      ),
    ],
  );
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.title, required this.value});

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    leading: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.field,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18),
    ),
    title: Text(
      title,
      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
    ),
    subtitle: Text(
      value,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    ),
  );
}
