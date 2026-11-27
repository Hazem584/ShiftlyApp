import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';

import '../cubit/workspaces_cubit.dart';
import 'workspace_exit_dialog.dart';

class WorkspaceExitTile extends StatelessWidget {
  const WorkspaceExitTile({super.key});
  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionCoordinator?>();
    final workspaces = context.read<WorkspacesCubit?>();
    if (session == null || workspaces == null || !workspaces.canLeave) {
      return const SizedBox.shrink();
    }
    return BlocBuilder<SessionCoordinator, SessionState>(
      bloc: session,
      builder: (context, session) {
        final membership = session.activeMembership;
        if (membership == null || !context.read<WorkspacesCubit>().canLeave) {
          return const SizedBox.shrink();
        }
        final m = membership.role == WorkspaceRole.manager;
        return BlocBuilder<WorkspacesCubit, WorkspacesState>(
          builder: (context, state) => ListTile(
            key: const Key('leave-workspace'),
            leading: Icon(
              m ? Icons.delete_forever_outlined : Icons.exit_to_app,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              context.tr(
                m ? 'Delete workspace for everyone' : 'Leave workspace',
              ),
            ),
            subtitle: Text(membership.workspace.name),
            enabled: !state.busy,
            onTap: () => _confirm(context, membership, m),
          ),
        );
      },
    );
  }

  Future<void> _confirm(
    BuildContext context,
    WorkspaceMembership membership,
    bool manager,
  ) async {
    final typed = await showDialog<String>(
      context: context,
      builder: (_) => WorkspaceExitDialog(
        workspaceName: membership.workspace.name,
        manager: manager,
      ),
    );
    if (typed == null || !context.mounted) return;
    final cubit = context.read<WorkspacesCubit>();
    final ok = await cubit.leave(
      membership.workspace.id,
      confirmation: manager ? typed : null,
    );
    if (!ok && context.mounted) {
      final msg =
          cubit.state.failure?.message ??
          'Could not leave workspace. Please retry.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr(msg))));
    }
  }
}
