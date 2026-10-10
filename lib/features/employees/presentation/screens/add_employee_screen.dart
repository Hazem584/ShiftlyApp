import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_cubit.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_form_actions.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_form_header.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({super.key});
  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _jobTitle = TextEditingController();
  var _valid = false;
  var _submitting = false;

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
      final invitation = await context.read<EmployeesCubit>().invite(
        email: _email.text.trim().toLowerCase(),
        jobTitle: _jobTitle.text.trim().isEmpty ? null : _jobTitle.text.trim(),
      );
      if (!mounted || invitation == null) return;
      final token = invitation.inviteToken;
      if (token != null) await _showToken(token);
      if (mounted) context.pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      ToastService.error(context, message: error.toFailure().message);
    } catch (_) {
      if (!mounted) return;
      ToastService.error(context, message: 'Could not create invitation.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showToken(String token) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: Text(context.tr('Invitation created')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(
              'Share this one-time token only with the intended employee.',
            ),
          ),
          const SizedBox(height: 12),
          SelectableText(token, key: const Key('invitation-token')),
        ],
      ),
      actions: [
        TextButton.icon(
          key: const Key('copy-invitation-token'),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: token));
            if (dialogContext.mounted) {
              ToastService.success(dialogContext, message: 'Token copied');
            }
          },
          icon: const Icon(Icons.copy_rounded),
          label: Text(context.tr('Copy')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(context.tr('Done')),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.tr('Invite Employee')),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppPalette.of(context).borderColor),
      ),
    ),
    body: SafeArea(
      top: false,
      child: Form(
        key: _formKey,
        onChanged: _revalidate,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          key: const Key('add-employee-form'),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
          children: [
            const EmployeeFormHeader(),
            const SizedBox(height: 18),
            TextFormField(
              key: const Key('email-field'),
              controller: _email,
              enabled: !_submitting,
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
              controller: _jobTitle,
              enabled: !_submitting,
              maxLength: 120,
              decoration: InputDecoration(
                labelText: context.tr('Job title (optional)'),
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
            ),
            EmployeeFormActions(
              submitting: _submitting,
              canSubmit: _valid,
              onCancel: context.pop,
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    ),
  );
}
