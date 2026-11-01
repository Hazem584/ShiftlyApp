import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/workspaces/presentation/cubit/workspaces_cubit.dart';

import '../design/access_action.dart';
import '../design/access_field.dart';
import '../design/access_notice.dart';
import '../design/access_page.dart';

class JoinWorkspaceScreen extends StatefulWidget {
  const JoinWorkspaceScreen({super.key});
  @override
  State<JoinWorkspaceScreen> createState() => _JoinWorkspaceScreenState();
}

class _JoinWorkspaceScreenState extends State<JoinWorkspaceScreen> {
  final _token = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _obscure = true;
  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cubit = context.read<WorkspacesCubit>();
    if (cubit.state.busy || !(_form.currentState?.validate() ?? false)) return;
    final user = context.read<SessionCoordinator>().state.currentUser?.id;
    final success = await cubit.accept(_token.text.trim());
    if (!mounted ||
        !success ||
        context.read<SessionCoordinator>().state.currentUser?.id != user) {
      return;
    }
    _token.clear();
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<WorkspacesCubit, WorkspacesState>(
        builder: (context, state) => AccessPage(
          title: 'Join with token',
          subtitle: 'Paste the token shared by your manager.',
          onBack: state.busy ? null : () => Navigator.pop(context),
          footer: AccessAction(
            actionKey: const Key('accept-invitation'),
            label: context.tr('Accept invitation'),
            busy: state.accepting,
            onPressed: state.busy ? null : _submit,
          ),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AccessField(
                  label: context.tr('One-time invitation token'),
                  child: TextFormField(
                    key: const Key('invitation-token-field'),
                    controller: _token,
                    enabled: !state.busy,
                    textDirection: TextDirection.ltr,
                    obscureText: _obscure,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) => (v?.trim().isEmpty ?? true)
                        ? context.tr('Invitation token is required')
                        : null,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        tooltip: context.tr(
                          _obscure
                              ? 'Show invitation token'
                              : 'Hide invitation token',
                        ),
                        onPressed: state.busy
                            ? null
                            : () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const AccessNotice(
                  'This one-time token joins the workspace directly. Check who sent it before accepting.',
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
}
