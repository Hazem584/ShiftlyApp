import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';

import '../design/access_action.dart';
import '../design/access_field.dart';
import '../design/access_notice.dart';
import '../design/access_page.dart';
import '../widgets/access_password_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SessionCoordinator, SessionState>(
        builder: (context, state) {
          final loading =
              state.status == SessionStatus.registering ||
              state.status == SessionStatus.loadingCurrentUser;
          return AccessPage(
            title: 'Create account',
            subtitle: 'A few details to get started.',
            onBack: loading ? null : () => context.go('/login'),
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AccessAction(
                  actionKey: const Key('register-submit'),
                  label: context.tr('Create account'),
                  busy: loading,
                  onPressed: () => _submit(loading),
                ),
                TextButton(
                  key: const Key('register-sign-in'),
                  onPressed: loading ? null : () => context.go('/login'),
                  child: Text(context.tr('Already have an account? Sign in')),
                ),
              ],
            ),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AccessField(
                      label: context.tr('Email address'),
                      child: TextFormField(
                        key: const Key('register-email'),
                        controller: _email,
                        enabled: !loading,
                        textDirection: TextDirection.ltr,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        autocorrect: false,
                        decoration: const InputDecoration(),
                        validator: (v) =>
                            RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(v?.trim() ?? '')
                            ? null
                            : context.tr('Enter a valid email address'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AccessPasswordField(
                      fieldKey: const Key('register-password'),
                      controller: _password,
                      label: context.tr('Password'),
                      enabled: !loading,
                      hint: context.tr('Create a strong password'),
                      validator: (v) => (v?.length ?? 0) < 8
                          ? context.tr('Use at least 8 characters')
                          : null,
                    ),
                    const SizedBox(height: 20),
                    AccessPasswordField(
                      fieldKey: const Key('register-confirm-password'),
                      controller: _confirmPassword,
                      label: context.tr('Confirm password'),
                      enabled: !loading,
                      last: true,
                      hint: context.tr('Repeat your password'),
                      onSubmitted: (_) => _submit(loading),
                      validator: (v) => v != _password.text
                          ? context.tr('Passwords do not match')
                          : null,
                    ),
                    const SizedBox(height: 20),
                    const AccessNotice(
                      'Use at least 8 characters. Keep your password private.',
                    ),
                    if (state.failure != null) ...[
                      const SizedBox(height: 16),
                      AccessNotice('', failure: state.failure),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      );
  void _submit(bool loading) {
    if (loading || !(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<SessionCoordinator>().signUp(
      email: _email.text.trim().toLowerCase(),
      password: _password.text,
    );
  }
}
