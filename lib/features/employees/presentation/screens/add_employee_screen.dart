import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/features/employees/presentation/screens/add_employee_form_fields.dart';
import 'package:shiftly/features/employees/presentation/screens/invitation_token_dialog.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_form_actions.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({this.onDone, super.key});
  final VoidCallback? onDone;
  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _jobTitle = TextEditingController();
  var _valid = false, _submitting = false;

  @override
  void dispose() {
    _email.dispose();
    _jobTitle.dispose();
    super.dispose();
  }

  void _revalidate() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (valid != _valid) setState(() => _valid = valid);
  }

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      final title = _jobTitle.text.trim();
      await submitEmployeeInvitation(
        context,
        email: _email.text.trim().toLowerCase(),
        jobTitle: title.isEmpty ? null : title,
        onDone: widget.onDone,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.tr('Invite Employee')),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: AppPalette.of(context).borderColor),
      ),
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: EmployeeFormActions(
          submitting: _submitting,
          canSubmit: _valid,
          onCancel: widget.onDone ?? context.pop,
          onSubmit: _submit,
        ),
      ),
    ),
    body: SafeArea(
      top: false,
      child: AddEmployeeFormFields(
        formKey: _formKey,
        emailController: _email,
        jobTitleController: _jobTitle,
        submitting: _submitting,
        onChanged: _revalidate,
      ),
    ),
  );
}
