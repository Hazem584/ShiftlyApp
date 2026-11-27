import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class AddEmployeeFormFields extends StatelessWidget {
  const AddEmployeeFormFields({
    required this.formKey,
    required this.emailController,
    required this.jobTitleController,
    required this.submitting,
    required this.onChanged,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController jobTitleController;
  final bool submitting;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Form(
    key: formKey,
    onChanged: onChanged,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    child: ListView(
      key: const Key('add-employee-form'),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
      children: [
        Text(
          context.tr('An invitation gives access after acceptance.'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        TextFormField(
          key: const Key('email-field'),
          controller: emailController,
          enabled: !submitting,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: context.tr('Employee email'),
            prefixIcon: const Icon(Icons.email_outlined),
          ),
          validator: (value) =>
              RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                  .hasMatch(value?.trim() ?? '')
              ? null
              : 'Enter a valid email address',
        ),
        const SizedBox(height: 14),
        TextFormField(
          key: const Key('job-title-field'),
          controller: jobTitleController,
          enabled: !submitting,
          maxLength: 120,
          decoration: InputDecoration(
            labelText: context.tr('Job title (optional)'),
            prefixIcon: const Icon(Icons.badge_outlined),
          ),
        ),
      ],
    ),
  );
}
