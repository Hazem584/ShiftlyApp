import 'package:flutter/material.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_form_header.dart';

class PersonalInformationSection extends StatelessWidget {
  const PersonalInformationSection({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const EmployeeFormSectionTitle(
        title: 'Personal information',
        subtitle: 'Basic contact details for this employee',
      ),
      const SizedBox(height: 14),
      EmployeeFormControl(
        label: 'Full name',
        child: TextFormField(
          key: const Key('full-name-field'),
          controller: nameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(hintText: 'Enter full name'),
          validator: (value) => (value?.trim().length ?? 0) < 3
              ? 'Enter the employee’s full name'
              : null,
        ),
      ),
      const SizedBox(height: 13),
      EmployeeFormControl(
        label: 'Phone number',
        child: TextFormField(
          key: const Key('phone-field'),
          controller: phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(hintText: 'Enter phone number'),
          validator: (value) =>
              (value?.replaceAll(RegExp(r'\D'), '').length ?? 0) < 8
              ? 'Enter a valid phone number'
              : null,
        ),
      ),
      const SizedBox(height: 13),
      EmployeeFormControl(
        label: 'Email address',
        child: TextFormField(
          key: const Key('email-field'),
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(hintText: 'Enter email address'),
          validator: (value) =>
              RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                  .hasMatch(value?.trim() ?? '')
              ? null
              : 'Enter a valid email address',
        ),
      ),
    ],
  );
}
