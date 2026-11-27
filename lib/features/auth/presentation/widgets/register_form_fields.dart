import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/auth_brand_header.dart';
import 'package:shiftly/core/widgets/auth_submit_button.dart';
import 'package:shiftly/features/auth/presentation/widgets/register_field_helpers.dart';

List<Widget> buildRegisterFormChildren(
  BuildContext context, {
  required bool loading,
  required TextEditingController emailController,
  required TextEditingController passwordController,
  required TextEditingController confirmController,
  required bool obscurePassword,
  required bool obscureConfirmation,
  required VoidCallback onTogglePassword,
  required VoidCallback onToggleConfirmation,
  required VoidCallback onSubmit,
}) => [
  AuthBrandHeader(
    title: context.tr('A few details to get started.'),
    subtitle: context.tr('Use the exact email address your manager invited.'),
  ),
  const SizedBox(height: AppSpacing.xl),
  TextFormField(
    key: const Key('register-email'),
    controller: emailController,
    textDirection: TextDirection.ltr,
    enabled: !loading,
    keyboardType: TextInputType.emailAddress,
    textInputAction: TextInputAction.next,
    autofillHints: const [AutofillHints.email],
    decoration: InputDecoration(
      labelText: context.tr('Email'),
      prefixIcon: const Icon(Icons.email_outlined),
    ),
    validator: (v) => validateRegisterEmail(context, v),
  ),
  const SizedBox(height: AppSpacing.m),
  TextFormField(
    key: const Key('register-password'),
    controller: passwordController,
    textDirection: TextDirection.ltr,
    enabled: !loading,
    obscureText: obscurePassword,
    textInputAction: TextInputAction.next,
    autofillHints: const [AutofillHints.newPassword],
    decoration: buildRegisterPasswordDecoration(
      context,
      label: 'Password',
      tooltip: obscurePassword ? 'Show password' : 'Hide password',
      obscure: obscurePassword,
      loading: loading,
      onToggle: onTogglePassword,
    ),
    validator: (v) => validateRegisterPassword(context, v),
  ),
  const SizedBox(height: AppSpacing.m),
  TextFormField(
    key: const Key('register-confirm-password'),
    controller: confirmController,
    textDirection: TextDirection.ltr,
    enabled: !loading,
    obscureText: obscureConfirmation,
    textInputAction: TextInputAction.done,
    autofillHints: const [AutofillHints.newPassword],
    onFieldSubmitted: (_) => onSubmit(),
    decoration: buildRegisterPasswordDecoration(
      context,
      label: 'Confirm password',
      tooltip: obscureConfirmation
          ? 'Show password confirmation'
          : 'Hide password confirmation',
      obscure: obscureConfirmation,
      loading: loading,
      onToggle: onToggleConfirmation,
    ),
    validator: (v) => v != passwordController.text
        ? context.tr('Passwords do not match')
        : null,
  ),
  const SizedBox(height: AppSpacing.l),
  AuthSubmitButton(
    buttonKey: const Key('register-submit'),
    label: 'Create account',
    loading: loading,
    onSubmit: onSubmit,
  ),
  const SizedBox(height: AppSpacing.s),
  TextButton(
    key: const Key('register-sign-in'),
    onPressed: loading ? null : () => context.go('/login'),
    child: Text(context.tr('Already have an account? Sign in')),
  ),
];
