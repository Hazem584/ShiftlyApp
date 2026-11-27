import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/localization/language_selector.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/theme/theme_selector.dart';
import 'package:shiftly/core/widgets/auth_brand_header.dart';
import 'package:shiftly/core/widgets/auth_submit_button.dart';

export 'package:shiftly/features/auth/presentation/widgets/login_session_expired.dart';

List<Widget> buildLoginFormChildren(
  BuildContext context, {
  required SessionState state,
  required bool loading,
  required bool acknowledgedExpiry,
  required TextEditingController emailController,
  required TextEditingController passwordController,
  required bool obscurePassword,
  required VoidCallback onTogglePassword,
  required VoidCallback onSubmit,
}) => [
  AuthBrandHeader(
    showWordmark: true,
    title: context.tr('Good work\nstarts here.'),
    subtitle: context.tr('Sign in to your everyday workspace.'),
  ),
  if (state.status == SessionStatus.unauthenticated &&
      state.failure != null &&
      !acknowledgedExpiry) ...[
    const SizedBox(height: AppSpacing.m),
    Text(
      state.failure!.message,
      key: const Key('login-session-message'),
      textAlign: TextAlign.center,
      style: TextStyle(color: AppPalette.of(context).error),
    ),
  ],
  const SizedBox(height: AppSpacing.xl),
  TextFormField(
    key: const Key('login-email'),
    controller: emailController,
    textDirection: TextDirection.ltr,
    enabled: !loading,
    keyboardType: TextInputType.emailAddress,
    textInputAction: TextInputAction.next,
    autofillHints: const [AutofillHints.email],
    decoration: InputDecoration(
      labelText: context.tr('Email'),
      hintText: context.tr('you@company.com'),
    ),
    validator: (v) =>
        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v?.trim() ?? '')
        ? null
        : context.tr('Enter a valid email address'),
  ),
  const SizedBox(height: AppSpacing.m),
  TextFormField(
    key: const Key('login-password'),
    controller: passwordController,
    textDirection: TextDirection.ltr,
    enabled: !loading,
    obscureText: obscurePassword,
    textInputAction: TextInputAction.done,
    autofillHints: const [AutofillHints.password],
    onFieldSubmitted: (_) => onSubmit(),
    decoration: InputDecoration(
      labelText: context.tr('Password'),
      suffixIcon: IconButton(
        onPressed: loading ? null : onTogglePassword,
        icon: Icon(
          obscurePassword
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
        ),
      ),
    ),
    validator: (v) =>
        v == null || v.isEmpty ? context.tr('Password is required') : null,
  ),
  const SizedBox(height: 32),
  AuthSubmitButton(
    buttonKey: const Key('login-submit'),
    label: 'Sign in',
    loading: loading,
    onSubmit: onSubmit,
  ),
  const SizedBox(height: AppSpacing.s),
  TextButton(
    key: const Key('login-create-account'),
    onPressed: loading ? null : () => context.go('/register'),
    child: Text(context.tr('Don\u2019t have an account? Create account')),
  ),
  const SizedBox(height: 24),
  const Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [LanguageSelector(), ThemeSelector()],
  ),
];
