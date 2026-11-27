import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/auth_page_layout.dart';
import 'package:shiftly/features/auth/presentation/widgets/register_form_fields.dart';

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
  bool _obscurePassword = true, _obscureConfirmation = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<SessionCoordinator, SessionState>(
        listenWhen: (previous, current) =>
            current.status == SessionStatus.failure && previous != current,
        listener: (context, state) => ToastService.error(
          context,
          message: state.failure?.message ?? 'Unable to create your account.',
        ),
        builder: (context, state) {
          final loading = state.status == SessionStatus.registering;
          return AuthPageLayout(
            child: Scaffold(
              appBar: AppBar(title: Text(context.tr('Create account'))),
              body: SafeArea(
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.l),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: buildRegisterFormChildren(
                              context,
                              loading: loading,
                              emailController: _email,
                              passwordController: _password,
                              confirmController: _confirmPassword,
                              obscurePassword: _obscurePassword,
                              obscureConfirmation: _obscureConfirmation,
                              onTogglePassword: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              onToggleConfirmation: () => setState(
                                () => _obscureConfirmation =
                                    !_obscureConfirmation,
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
    context.read<SessionCoordinator>().signUp(
      email: _email.text.trim().toLowerCase(),
      password: _password.text,
    );
  }
}
