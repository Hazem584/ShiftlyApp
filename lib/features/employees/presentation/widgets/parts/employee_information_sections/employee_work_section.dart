part of '../../employee_information_sections.dart';

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
        icon: Icons.badge_outlined,
        title: 'Job title',
        value: employee.displayJobTitle,
      ),
      _Detail(
        icon: Icons.calendar_today_outlined,
        title: 'Joined',
        value: employee.startDate == null
            ? 'Not provided'
            : '${employee.startDate!.day}/${employee.startDate!.month}/${employee.startDate!.year}',
      ),
    ],
  );

  String _employmentLabel(EmploymentStatus status) => switch (status) {
    EmploymentStatus.active => 'Active',
    EmploymentStatus.suspended => 'Suspended',
    EmploymentStatus.onLeave => 'On leave',
    EmploymentStatus.unknown => 'Unknown',
  };
}
