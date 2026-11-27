import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/auth_page_layout.dart';
import 'package:shiftly/features/auth/presentation/widgets/login_form_fields.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true, _acknowledgedExpiry = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<SessionCoordinator, SessionState>(
        listenWhen: (previous, current) =>
            current.status == SessionStatus.failure && previous != current,
        listener: (context, state) => ToastService.error(
          context,
          message: state.failure?.message ?? 'Unable to sign in.',
        ),
        builder: (context, state) {
          final loading = state.status == SessionStatus.authenticating;
          if (!_acknowledgedExpiry && state == const SessionState.expired()) {
            return buildExpiredSessionAccessScreen(
              context,
              message: state.failure!.message,
              onAcknowledge: () => setState(() => _acknowledgedExpiry = true),
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
                            children: buildLoginFormChildren(
                              context,
                              state: state,
                              loading: loading,
                              acknowledgedExpiry: _acknowledgedExpiry,
                              emailController: _email,
                              passwordController: _password,
                              obscurePassword: _obscurePassword,
                              onTogglePassword: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              onSubmit: () => _submit(loading),
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
    FocusScope.of(context).unfocus();
    context.read<SessionCoordinator>().signIn(
      email: _email.text,
      password: _password.text,
    );
  }
}
