part of '../../employee_information_sections.dart';

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
        value: employee.displayEmail,
      ),
      _Detail(
        icon: Icons.phone_outlined,
        title: 'Phone',
        value: employee.displayPhone,
      ),
    ],
  );
}
