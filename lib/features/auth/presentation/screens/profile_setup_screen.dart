import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/auth/presentation/widgets/profile_setup_fields.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<SessionCoordinator, SessionState>(
        listenWhen: (_, current) => current.status == SessionStatus.failure,
        listener: (context, state) => ToastService.error(
          context,
          message: state.failure?.message ?? 'Could not create your profile.',
        ),
        builder: (context, state) {
          final loading = state.status == SessionStatus.loadingCurrentUser;
          return Scaffold(
            appBar: AppBar(
              title: Text(context.tr('Your profile')),
              actions: [
                TextButton(
                  onPressed: loading
                      ? null
                      : context.read<SessionCoordinator>().signOut,
                  child: Text(context.tr('Sign out')),
                ),
              ],
            ),
            body: SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Form(
                      key: _key,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: buildProfileSetupFields(
                          context,
                          loading: loading,
                          nameController: _name,
                          phoneController: _phone,
                          onSubmit: _submit,
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

  void _submit() {
    if (!(_key.currentState?.validate() ?? false)) return;
    final phone = _phone.text.trim();
    context.read<SessionCoordinator>().bootstrapProfile(
      fullName: _name.text.trim(),
      phone: phone.isEmpty ? null : phone,
    );
  }
}
