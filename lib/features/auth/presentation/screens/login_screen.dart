import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/auth_brand_header.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
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
      message: state.failure?.message ?? 'Unable to sign in.',
    ),
    builder: (context, state) {
      final loading = state.status == SessionStatus.authenticating;
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
                          title: 'Welcome to Shiftly',
                          subtitle: 'Sign in to continue to your workspace. Use the email your manager invited.',
                        ),
                        if (state.status == SessionStatus.unauthenticated &&
                            state.failure != null) ...[
                          const SizedBox(height: AppSpacing.m),
                          Text(
                            state.failure!.message,
                            key: const Key('login-session-message'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        TextFormField(
                          key: const Key('login-email'),
                          controller: _email,
                          textDirection: TextDirection.ltr,
                          enabled: !loading,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            labelText: context.tr('Email'),
                            hintText: 'you@company.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(email)) {
                              return context.tr('Enter a valid email address');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.m),
                        TextFormField(
                          key: const Key('login-password'),
                          controller: _password,
                          textDirection: TextDirection.ltr,
                          enabled: !loading,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _submit(loading),
                          decoration: InputDecoration(
                            labelText: context.tr('Password'),
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
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
                          validator: (value) => value == null || value.isEmpty
                              ? context.tr('Password is required')
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.l),
                        FilledButton(
                          key: const Key('login-submit'),
                          onPressed: loading ? null : () => _submit(false),
                          child: loading
                              ? const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(context.tr('Sign in')),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        TextButton(
                          key: const Key('login-create-account'),
                          onPressed: loading
                              ? null
                              : () => context.go('/register'),
                          child: Text(
                            context.tr(
                              'Don\u2019t have an account? Create account',
                            ),
                          ),
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
    context.read<SessionCoordinator>().signIn(
      email: _email.text,
      password: _password.text,
    );
  }
}
