import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/features/employees/data/employee_repository.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_status_badge.dart';

class EmployeeDetailsScreen extends StatelessWidget {
  const EmployeeDetailsScreen({required this.employeeId, super.key});
  final String employeeId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Employee details')),
    body: FutureBuilder<Employee?>(
      future: context.read<EmployeeRepository>().getEmployee(employeeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final employee = snapshot.data;
        if (employee == null) {
          return const Center(child: Text('Employee not found'));
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    child: Text(
                      employee.initials,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    employee.fullName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    employee.jobTitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  EmployeeStatusBadge(status: employee.attendanceStatus),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Card(
              child: Column(
                children: [
                  _Detail(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    value: employee.email,
                  ),
                  const Divider(height: 1, indent: 56),
                  _Detail(
                    icon: Icons.phone_outlined,
                    title: 'Phone',
                    value: employee.phone,
                  ),
                  const Divider(height: 1, indent: 56),
                  _Detail(
                    icon: Icons.schedule_rounded,
                    title: 'Assigned shift',
                    value:
                        '${employee.shift.name}\n${employee.shift.timeRange}',
                  ),
                  const Divider(height: 1, indent: 56),
                  _Detail(
                    icon: Icons.location_on_outlined,
                    title: 'Workplace',
                    value: employee.location.name,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.title, required this.value});
  final IconData icon;
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) =>
      ListTile(leading: Icon(icon), title: Text(title), subtitle: Text(value));
}
