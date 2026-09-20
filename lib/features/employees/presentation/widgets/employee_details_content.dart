import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/employees/data/employee_repository.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_status_badge.dart';

class EmployeeDetailsContent extends StatelessWidget {
  const EmployeeDetailsContent({required this.employeeId, super.key});
  final String employeeId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Employee details')),
    body: FutureBuilder<Employee?>(
      future: context.read<EmployeeRepository>().getEmployee(employeeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _DetailsLoading();
        }
        final employee = snapshot.data;
        if (employee == null) {
          return const EmptyState(
            icon: Icons.person_search_outlined,
            title: 'Employee not found',
            message: 'This employee may no longer be available.',
          );
        }
        return ListView(
          key: const Key('employee-details-content'),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
          children: [
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Container(
                    height: 88,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.ink,
                          AppColors.orange,
                          AppColors.teal,
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
                            employee.fullName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        Text(
                          employee.jobTitle,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        EmployeeStatusBadge(status: employee.attendanceStatus),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Text(
              'Contact information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.s),
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _Detail(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    value: employee.email,
                  ),
                  const Divider(height: 1, indent: 58, endIndent: 14),
                  _Detail(
                    icon: Icons.phone_outlined,
                    title: 'Phone',
                    value: employee.phone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Text('Work details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.s),
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _Detail(
                    icon: Icons.work_outline_rounded,
                    title: 'Employment status',
                    value: _employmentLabel(employee.employmentStatus),
                  ),
                  const Divider(height: 1, indent: 58, endIndent: 14),
                  _Detail(
                    icon: Icons.location_on_outlined,
                    title: 'Workplace',
                    value: employee.location.name,
                  ),
                  const Divider(height: 1, indent: 58, endIndent: 14),
                  _Detail(
                    icon: Icons.schedule_outlined,
                    title: 'Assigned shift',
                    value:
                        '${employee.shift.name}\n${employee.shift.timeRange}',
                  ),
                  const Divider(height: 1, indent: 58, endIndent: 14),
                  _Detail(
                    icon: Icons.calendar_today_outlined,
                    title: 'Start date',
                    value:
                        '${employee.startDate.day}/${employee.startDate.month}/${employee.startDate.year}',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  static String _employmentLabel(EmploymentStatus status) => switch (status) {
    EmploymentStatus.active => 'Active',
    EmploymentStatus.onLeave => 'On leave',
    EmploymentStatus.inactive => 'Inactive',
  };
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

class _DetailsLoading extends StatelessWidget {
  const _DetailsLoading();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(18),
    child: Column(
      children: [
        Container(
          height: 245,
          decoration: BoxDecoration(
            color: AppColors.field,
            borderRadius: BorderRadius.circular(AppRadii.l),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: AppColors.field,
            borderRadius: BorderRadius.circular(AppRadii.l),
          ),
        ),
      ],
    ),
  );
}
