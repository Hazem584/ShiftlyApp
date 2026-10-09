import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/auth_brand_header.dart';

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
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<SessionCoordinator, SessionState>(
    listenWhen: (previous, current) =>
        current.status == SessionStatus.failure && previous != current,
    listener: (context, state) => ToastService.error(
      context,
      message: state.failure?.message ?? 'Unable to create your account.',
    ),
    builder: (context, state) {
      final loading = state.status == SessionStatus.registering;
      return Scaffold(
        body: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AuthBrandHeader(
                          title: 'Create your Shiftly account',
                          subtitle: 'Use the exact email address your manager invited.',
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        TextFormField(
                          key: const Key('register-email'),
                          controller: _email,
                          enabled: !loading,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(email)) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.m),
                        TextFormField(
                          key: const Key('register-password'),
                          controller: _password,
                          enabled: !loading,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: loading
                                  ? null
                                  : () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return 'Password is required';
                            }
                            if (value!.length < 8) {
                              return 'Use at least 8 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.m),
                        TextFormField(
                          key: const Key('register-confirm-password'),
                          controller: _confirmPassword,
                          enabled: !loading,
                          obscureText: _obscureConfirmation,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          onFieldSubmitted: (_) => _submit(loading),
                          decoration: InputDecoration(
                            labelText: 'Confirm password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              tooltip: _obscureConfirmation
                                  ? 'Show password confirmation'
                                  : 'Hide password confirmation',
                              onPressed: loading
                                  ? null
                                  : () => setState(
                                      () => _obscureConfirmation =
                                          !_obscureConfirmation,
                                    ),
                              icon: Icon(
                                _obscureConfirmation
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) => value != _password.text
                              ? 'Passwords do not match'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.l),
                        FilledButton(
                          key: const Key('register-submit'),
                          onPressed: loading ? null : () => _submit(false),
                          child: loading
                              ? const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Create account'),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        TextButton(
                          key: const Key('register-sign-in'),
                          onPressed: loading
                              ? null
                              : () => context.go('/login'),
                          child: const Text('Already have an account? Sign in'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
