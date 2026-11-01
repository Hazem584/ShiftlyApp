import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';

import '../design/access_action.dart';
import '../design/access_field.dart';
import '../design/access_notice.dart';
import '../design/access_page.dart';

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

  void _submit(bool loading) {
    if (loading || !(_key.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<SessionCoordinator>().bootstrapProfile(
      fullName: _name.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SessionCoordinator, SessionState>(
        builder: (context, state) {
          final loading = state.status == SessionStatus.loadingCurrentUser;
          return AccessPage(
            title: 'Your profile',
            subtitle: 'How should your team know you?',
            actions: [
              TextButton(
                onPressed: loading
                    ? null
                    : context.read<SessionCoordinator>().signOut,
                child: Text(context.tr('Sign out')),
              ),
            ],
            footer: AccessAction(
              actionKey: const Key('profile-setup-submit'),
              label: context.tr('Save and continue'),
              busy: loading,
              onPressed: () => _submit(loading),
            ),
            child: AutofillGroup(
              child: Form(
                key: _key,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AccessField(
                      label: context.tr('Full name'),
                      child: TextFormField(
                        key: const Key('profile-setup-name'),
                        controller: _name,
                        enabled: !loading,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        decoration: const InputDecoration(),
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? context.tr('Full name is required')
                            : v!.trim().length > 120
                            ? context.tr('Full name is too long')
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AccessField(
                      label: context.tr('Phone (optional)'),
                      child: TextFormField(
                        key: const Key('profile-setup-phone'),
                        controller: _phone,
                        enabled: !loading,
                        textDirection: TextDirection.ltr,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        onFieldSubmitted: (_) => _submit(loading),
                        decoration: const InputDecoration(),
                        validator: (v) => (v?.trim().length ?? 0) > 30
                            ? context.tr('Phone number is too long')
                            : null,
                      ),
                    ),
                    if (state.failure != null) ...[
                      const SizedBox(height: 20),
                      AccessNotice('', failure: state.failure),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      );
}
