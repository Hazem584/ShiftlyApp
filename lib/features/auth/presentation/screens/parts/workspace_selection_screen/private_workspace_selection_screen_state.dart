part of '../../workspace_selection_screen.dart';

class _WorkspaceSelectionScreenState extends State<WorkspaceSelectionScreen> {
  final _inviteToken = TextEditingController();
  bool _obscureInviteToken = true;

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
        title: const Text('Create workspace'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('workspace-name'),
              controller: name,
              decoration: const InputDecoration(labelText: 'Workspace name'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('workspace-timezone'),
              controller: timezone,
              decoration: const InputDecoration(labelText: 'Timezone'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('submit-workspace'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Create'),
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
    if (mounted && !success) {
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
    } else {
      ToastService.error(
        context,
        message:
            context.read<WorkspacesCubit>().state.failure?.message ??
            'Could not accept invitation.',
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<SessionCoordinator, SessionState>(
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
            memberships.isEmpty ? 'Workspace access' : 'Choose workspace',
          ),
          actions: [
            TextButton(
              onPressed: context.read<SessionCoordinator>().signOut,
              child: const Text('Sign out'),
            ),
          ],
        ),
        body: memberships.isNotEmpty
            ? WorkspaceMembershipChooser(
                memberships: memberships,
                onSelected: (membership) => context
                    .read<SessionCoordinator>()
                    .selectWorkspace(membership.workspace.id),
              )
            : BlocBuilder<WorkspacesCubit, WorkspacesState>(
                builder: (context, state) => ListView(
                  key: const Key('no-workspace-onboarding'),
                  padding: const EdgeInsets.all(AppSpacing.m),
                  children: [
                    const Text(
                      'Create a workspace for your team, or accept an invitation sent by a manager.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.l),
                    FilledButton.icon(
                      key: const Key('create-workspace'),
                      onPressed: state.creating ? null : _createWorkspace,
                      icon: const Icon(Icons.add_business_outlined),
                      label: const Text('Create workspace'),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    const Text(
                      'Have an invitation? Paste the one-time token your manager shared with you. For security, invitation lists never include this token.',
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
                        labelText: 'One-time invitation token',
                        prefixIcon: const Icon(Icons.key_outlined),
                        suffixIcon: IconButton(
                          tooltip: _obscureInviteToken
                              ? 'Show invitation token'
                              : 'Hide invitation token',
                          onPressed: state.accepting
                              ? null
                              : () => setState(
                                  () => _obscureInviteToken =
                                      !_obscureInviteToken,
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
                      label: const Text('Accept invitation'),
                    ),
                    if (state.invitations.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.l),
                      Text(
                        'Invitations for your account',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      for (final invitation in state.invitations)
                        ListTile(
                          leading: const Icon(Icons.mail_outline),
                          title: Text(
                            invitation.workspace?.name ??
                                'Workspace invitation',
                          ),
                          subtitle: Text(invitation.jobTitle ?? 'Employee'),
                        ),
                    ],
                    if (state.failure != null) ...[
                      const SizedBox(height: AppSpacing.m),
                      Text(state.failure!.message, textAlign: TextAlign.center),
                      TextButton(
                        onPressed: context.read<WorkspacesCubit>().load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ],
                ),
              ),
      );
    },
  );
}
