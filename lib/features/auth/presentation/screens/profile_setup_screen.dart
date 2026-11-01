import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/auth_brand_header.dart';

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
              title: Text(context.tr('Complete your profile')),
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
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Form(
                      key: _key,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AuthBrandHeader(
                            title: context.tr('Complete your profile'),
                            subtitle: context.tr(
                              'Tell us how your name and phone should appear in Shiftly.',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.l),
                          TextFormField(
                            key: const Key('profile-setup-name'),
                            controller: _name,
                            enabled: !loading,
                            decoration: InputDecoration(
                              labelText: context.tr('Full name'),
                            ),
                            validator: (value) {
                              final length = value?.trim().length ?? 0;
                              if (length < 1) {
                                return context.tr('Full name is required');
                              }
                              if (length > 120) {
                                return context.tr('Full name is too long');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.m),
                          TextFormField(
                            key: const Key('profile-setup-phone'),
                            controller: _phone,
                            enabled: !loading,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: context.tr('Phone (optional)'),
                            ),
                            validator: (value) =>
                                (value?.trim().length ?? 0) > 30
                                ? context.tr('Phone number is too long')
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.l),
                          FilledButton(
                            key: const Key('profile-setup-submit'),
                            onPressed: loading
                                ? null
                                : () {
                                    if (!(_key.currentState?.validate() ??
                                        false)) {
                                      return;
                                    }
                                    context
                                        .read<SessionCoordinator>()
                                        .bootstrapProfile(
                                          fullName: _name.text.trim(),
                                          phone: _phone.text.trim().isEmpty
                                              ? null
                                              : _phone.text.trim(),
                                        );
                                  },
                            child: loading
                                ? const SizedBox.square(
                                    dimension: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(context.tr('Continue')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
}
