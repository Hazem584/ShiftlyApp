import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/workspaces/presentation/cubit/workspaces_cubit.dart';

import '../design/access_action.dart';
import '../design/access_field.dart';
import '../design/access_notice.dart';
import '../design/access_page.dart';

/// State owns controllers until this route's exit transition has finished.
class CreateWorkspaceScreen extends StatefulWidget {
  const CreateWorkspaceScreen({super.key});
  @override
  State<CreateWorkspaceScreen> createState() => _CreateWorkspaceScreenState();
}

class _CreateWorkspaceScreenState extends State<CreateWorkspaceScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _timezone = TextEditingController(text: 'Africa/Cairo');
  @override
  void dispose() {
    _name.dispose();
    _timezone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cubit = context.read<WorkspacesCubit>();
    if (cubit.state.busy || !(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final user = context.read<SessionCoordinator>().state.currentUser?.id;
    final success = await cubit.create(
      name: _name.text.trim(),
      timezone: _timezone.text.trim(),
    );
    if (!mounted ||
        !success ||
        context.read<SessionCoordinator>().state.currentUser?.id != user) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<WorkspacesCubit, WorkspacesState>(
        builder: (context, state) => AccessPage(
          title: 'Create workspace',
          onBack: state.busy ? null : () => Navigator.pop(context),
          footer: AccessAction(
            actionKey: const Key('submit-workspace'),
            label: context.tr('Create workspace'),
            busy: state.creating,
            onPressed: state.busy ? null : _submit,
          ),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AccessField(
                  label: context.tr('Workspace name'),
                  child: TextFormField(
                    key: const Key('workspace-name'),
                    controller: _name,
                    enabled: !state.busy,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(),
                    validator: (v) => (v?.trim().isEmpty ?? true)
                        ? context.tr('Workspace name is required')
                        : v!.trim().length > 120
                        ? context.tr('Workspace name is too long')
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                AccessField(
                  label: context.tr('Timezone'),
                  child: TextFormField(
                    key: const Key('workspace-timezone'),
                    controller: _timezone,
                    enabled: !state.busy,
                    textDirection: TextDirection.ltr,
                    autocorrect: false,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(),
                    validator: (v) => (v?.trim().isEmpty ?? true)
                        ? context.tr('Timezone is required')
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                const AccessNotice(
                  'Schedules and attendance use this workspace’s timezone.',
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
