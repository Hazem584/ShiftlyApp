import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/localization/language_selector.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/theme/theme_selector.dart';
import 'package:shiftly/core/widgets/access_screen.dart';
import 'package:shiftly/core/widgets/auth_brand_header.dart';
import 'package:shiftly/core/widgets/auth_page_layout.dart';

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
  bool _acknowledgedExpiry = false;

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
      if (!_acknowledgedExpiry && state == const SessionState.expired()) {
        return AccessScreen(
          title: 'Session expired',
          actions: [
            FilledButton(
              onPressed: () => setState(() => _acknowledgedExpiry = true),
              child: Text(context.tr('Sign in')),
            ),
          ],
          children: [
            Text(
              context.tr('Let’s sign you in again.'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 18),
            Text(
              context.tr(state.failure!.message),
              key: const Key('login-session-message'),
            ),
          ],
        );
      }

      return AuthPageLayout(
        child: Scaffold(
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
                          AuthBrandHeader(
                            showWordmark: true,
                            title: context.tr('Good work\nstarts here.'),
                            subtitle: context.tr(
                              'Sign in to your everyday workspace.',
                            ),
                          ),
                          if (state.status == SessionStatus.unauthenticated &&
                              state.failure != null &&
                              !_acknowledgedExpiry) ...[
                            const SizedBox(height: AppSpacing.m),
                            Text(
                              state.failure!.message,
                              key: const Key('login-session-message'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppPalette.of(context).error,
                              ),
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
                              hintText: context.tr('you@company.com'),
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                  .hasMatch(email)) {
                                return context.tr(
                                  'Enter a valid email address',
                                );
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

                              suffixIcon: IconButton(
                                onPressed: loading
                                    ? null
                                    : () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
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
                          const SizedBox(height: 32),
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
                          const SizedBox(height: 24),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [LanguageSelector(), ThemeSelector()],
                          ),
                        ],
                      ),
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
