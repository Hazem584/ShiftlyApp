import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/ease_hint.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/auth/presentation/widgets/workspace_membership_chooser.dart';
import 'package:shiftly/features/workspaces/presentation/cubit/workspaces_cubit.dart';

class WorkspaceSelectionScreen extends StatefulWidget {
  const WorkspaceSelectionScreen({super.key});
  @override
  State<WorkspaceSelectionScreen> createState() =>
      _WorkspaceSelectionScreenState();
}

class _WorkspaceSelectionScreenState extends State<WorkspaceSelectionScreen> {
  final _inviteToken = TextEditingController();
  bool _obscureInviteToken = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<WorkspacesCubit>().load();
    });
  }

  @override
  void dispose() {
    _inviteToken.dispose();
    super.dispose();
  }

  Future<void> _createWorkspace() async {
    final name = TextEditingController();
    final timezone = TextEditingController(text: 'Africa/Cairo');
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Create workspace')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('workspace-name'),
              controller: name,
              decoration: InputDecoration(
                labelText: context.tr('Workspace name'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('workspace-timezone'),
              controller: timezone,
              decoration: InputDecoration(labelText: context.tr('Timezone')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            key: const Key('submit-workspace'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('Create')),
          ),
        ],
      ),
    );
    final workspaceName = name.text;
    final workspaceTimezone = timezone.text;
    name.dispose();
    timezone.dispose();
    if (submitted != true || !mounted || workspaceName.trim().isEmpty) return;
    final success = await context.read<WorkspacesCubit>().create(
      name: workspaceName,
      timezone: workspaceTimezone,
    );
    if (!mounted) return;
    if (success) {
      _openWorkspace();
    } else {
      ToastService.error(context, message: 'Could not create workspace.');
    }
  }

  Future<void> _acceptInvitation() async {
    final token = _inviteToken.text.trim();
    if (token.isEmpty) return;
    final success = await context.read<WorkspacesCubit>().accept(token);
    if (!mounted) return;
    if (success) {
      _inviteToken.clear();
      _openWorkspace();
    } else {
      ToastService.error(
        context,
        message:
            context.read<WorkspacesCubit>().state.failure?.message ??
            'Could not accept invitation.',
      );
    }
  }

  void _openWorkspace() {
    final session = context.read<SessionCoordinator>().state;
    if (session.isAuthenticated) {
      context.go(
        session.status == SessionStatus.authenticatedManager
            ? '/dashboard'
            : '/employee',
      );
    }
  }

  Future<void> _selectWorkspace(WorkspaceMembership membership) async {
    final result = await context.read<SessionCoordinator>().selectWorkspace(
      membership.workspace.id,
    );
    if (mounted && result == WorkspaceSwitchResult.success) _openWorkspace();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SessionCoordinator, SessionState>(
        builder: (context, session) {
          final memberships =
              session.currentUser?.memberships
                  .where(
                    (item) =>
                        item.status == MembershipStatus.active &&
                        item.role != WorkspaceRole.unknown,
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
            body: BlocBuilder<WorkspacesCubit, WorkspacesState>(
              builder: (context, state) => ListView(
                key: Key(
                  memberships.isEmpty
                      ? 'no-workspace-onboarding'
                      : 'workspace-access',
                ),
                padding: const EdgeInsets.all(AppSpacing.m),
                children: [
                  if (memberships.isNotEmpty) ...[
                    WorkspaceMembershipChooser(
                      memberships: memberships,
                      currentWorkspaceId:
                          session.activeMembership?.workspace.id,
                      shrinkWrap: true,
                      onSelected: _selectWorkspace,
                    ),
                    const Divider(),
                  ],
                  const EaseHint(
                    icon: Icons.apartment_outlined,
                    message: 'Create a workspace for your team, or accept an invitation sent by a manager.',
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    context.tr(
                      'Create a workspace for your team, or accept an invitation sent by a manager.',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.l),
                  FilledButton.icon(
                    key: const Key('create-workspace'),
                    onPressed: state.creating ? null : _createWorkspace,
                    icon: const Icon(Icons.add_business_outlined),
                    label: Text(context.tr('Create workspace')),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  Text(
                    context.tr(
                      'Have an invitation? Paste the one-time token your manager shared with you. For security, invitation lists never include this token.',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  TextField(
                    key: const Key('invitation-token-field'),
                    controller: _inviteToken,
                    enabled: !state.accepting,
                    obscureText: _obscureInviteToken,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: context.tr('One-time invitation token'),
                      prefixIcon: const Icon(Icons.key_outlined),
                      suffixIcon: IconButton(
                        tooltip: _obscureInviteToken
                            ? 'Show invitation token'
                            : 'Hide invitation token',
                        onPressed: state.accepting
                            ? null
                            : () => setState(
                                () =>
                                    _obscureInviteToken = !_obscureInviteToken,
                              ),
                        icon: Icon(
                          _obscureInviteToken
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  OutlinedButton.icon(
                    key: const Key('accept-invitation'),
                    onPressed: state.accepting ? null : _acceptInvitation,
                    icon: state.accepting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.mark_email_read_outlined),
                    label: Text(context.tr('Accept invitation')),
                  ),
                  if (state.invitations.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.l),
                    Text(
                      context.tr('Invitations for your account'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    for (final invitation in state.invitations)
                      ListTile(
                        leading: const Icon(Icons.mail_outline),
                        title: Text(
                          invitation.workspace?.name ??
                              context.tr('Workspace invitation'),
                        ),
                        subtitle: Text(
                          invitation.jobTitle ?? context.tr('Employee'),
                        ),
                      ),
                  ],
                  if (state.failure != null) ...[
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      context.tr(state.failure!.message),
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: context.read<WorkspacesCubit>().load,
                      child: Text(context.tr('Retry')),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
}
