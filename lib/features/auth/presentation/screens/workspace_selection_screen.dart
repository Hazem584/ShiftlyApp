import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/auth/presentation/screens/workspace_selection_actions.dart';
import 'package:shiftly/features/auth/presentation/screens/workspace_selection_body.dart';
import 'package:shiftly/features/workspaces/presentation/cubit/workspaces_cubit.dart';

class WorkspaceSelectionScreen extends StatefulWidget {
  const WorkspaceSelectionScreen({super.key});
  @override
  State<WorkspaceSelectionScreen> createState() =>
      _WorkspaceSelectionScreenState();
}

class _WorkspaceSelectionScreenState extends State<WorkspaceSelectionScreen> {
  WorkspaceMembership? _selectedWorkspace;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<WorkspacesCubit>().load();
    });
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SessionCoordinator, SessionState>(
        builder: (context, session) {
          final memberships =
              session.currentUser?.memberships
                  .where(
                    (i) =>
                        i.status == MembershipStatus.active &&
                        i.role != WorkspaceRole.unknown,
                  )
                  .toList(growable: false) ??
              const <WorkspaceMembership>[];
          return Scaffold(
            appBar: AppBar(
              title: Text(
                memberships.isEmpty
                    ? context.tr('Workspace access')
                    : context.tr('Choose workspace'),
              ),
              actions: [
                TextButton(
                  onPressed: context.read<SessionCoordinator>().signOut,
                  child: Text(context.tr('Sign out')),
                ),
              ],
            ),
            bottomNavigationBar: memberships.isEmpty
                ? null
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: FilledButton(
                        key: const Key('continue-workspace'),
                        onPressed: () => selectWorkspaceMembership(
                          context,
                          _selectedWorkspace ?? memberships.first,
                        ),
                        child: Text(context.tr('Continue to workspace')),
                      ),
                    ),
                  ),
            body: buildWorkspaceSelectionBody(
              context,
              memberships: memberships,
              activeWorkspaceId: session.activeMembership?.workspace.id,
              selectedWorkspaceId: _selectedWorkspace?.workspace.id,
              onSelect: (m) => setState(() => _selectedWorkspace = m),
            ),
          );
        },
      );
}
