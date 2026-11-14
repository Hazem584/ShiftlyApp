import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/models/employee.dart';

class EmployeeListEmployeeCard extends StatelessWidget {
  const EmployeeListEmployeeCard({super.key, required this.employee});
  final Employee employee;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = employee.employmentStatus == EmploymentStatus.active
        ? switch (employee.attendanceStatus) {
            AttendanceStatus.present => 'On shift',
            AttendanceStatus.late => 'Late',
            AttendanceStatus.absent => 'Absent',
            _ => 'Not started',
          }
        : 'Inactive';
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.primary,
          child: Text(employee.initials),
        ),
        title: Text(
          employee.displayName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(employee.displayJobTitle),
            const SizedBox(height: 4),
            Text(
              context.tr(status),
              style: TextStyle(
                fontSize: 12,
                color: status == 'Late'
                    ? colors.error
                    : status == 'On shift'
                    ? Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFA9F1D8)
                          : const Color(0xFF087F66)
                    : colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        onTap: () => context.push('/employees/${employee.id}'),
      ),
    );
  }
}
