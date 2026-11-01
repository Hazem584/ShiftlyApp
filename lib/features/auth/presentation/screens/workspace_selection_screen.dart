import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/workspaces/presentation/cubit/workspaces_cubit.dart';

import '../design/access_action.dart';
import '../design/access_notice.dart';
import '../design/access_page.dart';
import '../design/access_tile.dart';
import '../widgets/access_navigation.dart';
import '../widgets/workspace_membership_chooser.dart';
import '../widgets/workspace_unavailable_view.dart';
import 'create_workspace_screen.dart';
import 'join_workspace_screen.dart';
import 'my_invitations_screen.dart';

class WorkspaceSelectionScreen extends StatefulWidget {
  const WorkspaceSelectionScreen({super.key});
  @override
  State<WorkspaceSelectionScreen> createState() =>
      _WorkspaceSelectionScreenState();
}

class _WorkspaceSelectionScreenState extends State<WorkspaceSelectionScreen> {
  String? _switching;
  bool _showOptions = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<WorkspacesCubit>().load();
    });
  }

  Future<void> _select(WorkspaceMembership membership) async {
    if (_switching != null) return;
    setState(() => _switching = membership.workspace.id);
    final coordinator = context.read<SessionCoordinator>();
    final result = await coordinator.selectWorkspace(membership.workspace.id);
    if (!mounted) return;
    setState(() => _switching = null);
    if (result == WorkspaceSwitchResult.success) {
      openAuthorizedWorkspace(context);
    } else if (result == WorkspaceSwitchResult.failure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('Unable to switch workspace. Please retry.'),
          ),
        ),
      );
    }
  }

  Future<void> _open(Widget screen) async {
    final success = await pushAccess<bool>(context, screen);
    if (mounted && success == true) openAuthorizedWorkspace(context);
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SessionCoordinator, SessionState>(
        builder: (context, session) =>
            BlocBuilder<WorkspacesCubit, WorkspacesState>(
              builder: (context, state) {
                final memberships = context
                    .read<SessionCoordinator>()
                    .selectableMemberships;
                final unavailable =
                    memberships.isEmpty &&
                    (session.currentUser?.memberships.isNotEmpty ?? false);
                final busy = state.busy || _switching != null;
                if (unavailable && !_showOptions) {
                  return WorkspaceUnavailableView(
                    onChoose: () => setState(() => _showOptions = true),
                    onSignOut: context.read<SessionCoordinator>().signOut,
                  );
                }
                return AccessPage(
                  title: 'Choose workspace',
                  subtitle: 'Your role belongs to each workspace.',
                  actions: [
                    TextButton(
                      onPressed: busy
                          ? null
                          : context.read<SessionCoordinator>().signOut,
                      child: Text(context.tr('Sign out')),
                    ),
                  ],
                  footer: AccessAction(
                    actionKey: const Key('create-workspace'),
                    label: context.tr('Create workspace'),
                    onPressed: busy
                        ? null
                        : () => _open(const CreateWorkspaceScreen()),
                  ),
                  child: Column(
                    key: Key(
                      memberships.isEmpty
                          ? 'no-workspace-onboarding'
                          : 'workspace-access',
                    ),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (memberships.isNotEmpty)
                        WorkspaceMembershipChooser(
                          memberships: memberships,
                          currentWorkspaceId:
                              session.activeMembership?.workspace.id,
                          currentSelectionId: '',
                          switchingWorkspaceId: _switching,
                          shrinkWrap: true,
                          onSelected: _select,
                        ),
                      if (memberships.isEmpty) ...[
                        AccessNotice(
                          unavailable
                              ? 'This workspace is unavailable. Your membership may be suspended or removed. Contact your manager or choose another workspace.'
                              : 'Create a workspace for your team, or accept an invitation sent by a manager.',
                        ),
                        const SizedBox(height: 12),
                      ],
                      AccessTile(
                        key: const Key('my-invitations'),
                        icon: 'file',
                        title: context.tr('Pending invitations'),
                        subtitle: context.tr(
                          '{count} invitation(s) waiting for you',
                          {'count': '${state.invitations.length}'},
                        ),
                        onTap: busy
                            ? null
                            : () => _open(const MyInvitationsScreen()),
                      ),
                      const SizedBox(height: 12),
                      AccessTile(
                        key: const Key('invitation-code-expander'),
                        icon: 'plus',
                        title: context.tr('Join with a token'),
                        subtitle: context.tr('Use your one-time invitation'),
                        onTap: busy
                            ? null
                            : () => _open(const JoinWorkspaceScreen()),
                      ),
                      if (state.loading) ...[
                        const SizedBox(height: 20),
                        const LinearProgressIndicator(),
                      ],
                      if (state.failure != null) ...[
                        const SizedBox(height: 16),
                        AccessNotice('', failure: state.failure),
                        TextButton(
                          onPressed: state.loading
                              ? null
                              : context.read<WorkspacesCubit>().load,
                          child: Text(context.tr('Retry')),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
      );
}
