import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/localization/language_selector.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/theme/theme_selector.dart';

import '../design/access_action.dart';
import '../design/access_brand.dart';
import '../design/access_field.dart';
import '../design/access_notice.dart';
import '../design/access_theme.dart';
import '../widgets/access_expired_view.dart';

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
  bool _expiredAcknowledged = false;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<SessionCoordinator, SessionState>(
    builder: (context, state) {
      final loading =
          state.status == SessionStatus.authenticating ||
          state.status == SessionStatus.loadingCurrentUser;
      final expired =
          !_expiredAcknowledged &&
          (state.status == SessionStatus.sessionExpired ||
              (state.status == SessionStatus.unauthenticated &&
                  state.failure?.kind.name == 'authentication'));
      if (expired) {
        return AccessExpiredView(
          onSignIn: () => setState(() => _expiredAcknowledged = true),
        );
      }
      return AccessTheme(
        child: Builder(
          builder: (context) => Scaffold(
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, box) => Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: (box.maxHeight - 52).clamp(
                            0,
                            double.infinity,
                          ),
                        ),
                        child: IntrinsicHeight(
                          child: AutofillGroup(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const AccessBrand(),
                                  const SizedBox(height: 48),
                                  Text(
                                    context.tr(
                                      expired
                                          ? 'Let’s sign you in again.'
                                          : 'Good work\nstarts here.',
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge,
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    context.tr(
                                      'Sign in to your everyday workspace.',
                                    ),
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 44),
                                  if (expired) ...[
                                    AccessNotice(
                                      'Your session has expired. Please sign in again.',
                                      failure: state.failure,
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                  AccessField(
                                    label: context.tr('Email address'),
                                    child: TextFormField(
                                      key: const Key('login-email'),
                                      controller: _email,
                                      enabled: !loading,
                                      textDirection: TextDirection.ltr,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.email,
                                      ],
                                      autocorrect: false,
                                      decoration: InputDecoration(
                                        hintText: context.tr('you@company.com'),
                                      ),
                                      validator: (v) =>
                                          RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                              .hasMatch(v?.trim() ?? '')
                                          ? null
                                          : context.tr(
                                              'Enter a valid email address',
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  AccessField(
                                    label: context.tr('Password'),
                                    child: TextFormField(
                                      key: const Key('login-password'),
                                      controller: _password,
                                      enabled: !loading,
                                      textDirection: TextDirection.ltr,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.password,
                                      ],
                                      onFieldSubmitted: (_) => _submit(loading),
                                      decoration: InputDecoration(
                                        suffixIcon: IconButton(
                                          tooltip: context.tr(
                                            _obscurePassword
                                                ? 'Show password'
                                                : 'Hide password',
                                          ),
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
                                      validator: (v) => v == null || v.isEmpty
                                          ? context.tr('Password is required')
                                          : null,
                                    ),
                                  ),
                                  if (state.failure != null && !expired) ...[
                                    const SizedBox(height: 20),
                                    AccessNotice('', failure: state.failure),
                                  ],
                                  const SizedBox(height: 40),
                                  const Spacer(),
                                  const SizedBox(height: 20),
                                  AccessAction(
                                    actionKey: const Key('login-submit'),
                                    label: context.tr('Sign in'),
                                    busy: loading,
                                    onPressed: () => _submit(loading),
                                  ),
                                  const SizedBox(height: 20),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        context.tr('New to Shiftly?'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                      TextButton(
                                        key: const Key('login-create-account'),
                                        onPressed: loading
                                            ? null
                                            : () => context.go('/register'),
                                        child: Text(
                                          context.tr('Create account'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 28),
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      LanguageSelector(),
                                      Text('English · العربية'),
                                      ThemeSelector(),
                                    ],
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
              ),
            ),
          ),
        ),
      );
    },
  );
  void _submit(bool loading) {
    if (loading || !(_formKey.currentState?.validate() ?? false)) return;
    _expiredAcknowledged = true;
    FocusScope.of(context).unfocus();
    context.read<SessionCoordinator>().signIn(
      email: _email.text.trim().toLowerCase(),
      password: _password.text,
    );
  }
}
