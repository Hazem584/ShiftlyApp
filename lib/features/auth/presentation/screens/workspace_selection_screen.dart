import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/access_screen.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/core/widgets/ease_hint.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/auth/presentation/screens/workspace_entry_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/workspace_invitation_list_screen.dart';
import 'package:shiftly/features/auth/presentation/widgets/workspace_access_link.dart';
import 'package:shiftly/features/auth/presentation/widgets/workspace_membership_chooser.dart';
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

  Future<void> _createWorkspace() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute<({String value, String timezone})>(
        builder: (_) => const WorkspaceEntryScreen(),
      ),
    );
    if (!mounted || result == null) return;
    final success = await context.read<WorkspacesCubit>().create(
      name: result.value,
      timezone: result.timezone,
    );
    if (!mounted) return;
    if (success) {
      _openWorkspace();
    } else {
      ToastService.error(context, message: 'Could not create workspace.');
    }
  }

  Future<void> _acceptInvitation() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute<({String value, String timezone})>(
        builder: (_) => const WorkspaceEntryScreen(join: true),
      ),
    );
    if (!mounted || result == null) return;
    final token = result.value;
    final success = await context.read<WorkspacesCubit>().accept(token);
    if (!mounted) return;
    if (success) {
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

  Future<void> _respondToInvitation(
    String invitationId, {
    required bool accept,
  }) async {
    final cubit = context.read<WorkspacesCubit>();
    final success = accept
        ? await cubit.acceptById(invitationId)
        : await cubit.decline(invitationId);
    if (!mounted) return;
    if (success) {
      if (accept) {
        _openWorkspace();
      } else {
        ToastService.success(context, message: 'Invitation declined.');
      }
    } else {
      ToastService.error(
        context,
        message:
            cubit.state.failure?.message ??
            'Could not update invitation. Please try again.',
      );
    }
  }

  Future<void> _selectWorkspace(WorkspaceMembership membership) async {
    final result = await context.read<SessionCoordinator>().selectWorkspace(
      membership.workspace.id,
    );
    if (!mounted) return;
    if (result == WorkspaceSwitchResult.success) {
      _openWorkspace();
    } else if (result == WorkspaceSwitchResult.failure ||
        result == WorkspaceSwitchResult.invalid ||
        result == WorkspaceSwitchResult.noAlternative) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (pageContext) => AccessScreen(
            title: 'Workspace unavailable',
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(pageContext).pop(),
                child: Text(context.tr('Choose another workspace')),
              ),
            ],
            children: [
              Text(
                context.tr('This workspace is unavailable.'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('Choose another workspace or contact your manager.'),
              ),
            ],
          ),
        ),
      );
    }
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
            bottomNavigationBar: memberships.isEmpty
                ? null
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: FilledButton(
                        key: const Key('continue-workspace'),
                        onPressed: () => _selectWorkspace(
                          _selectedWorkspace ?? memberships.first,
                        ),
                        child: Text(context.tr('Continue to workspace')),
                      ),
                    ),
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
                  Text(context.tr('Your role belongs to each workspace.')),
                  const SizedBox(height: 16),
                  if (memberships.isNotEmpty) ...[
                    WorkspaceMembershipChooser(
                      memberships: memberships,
                      currentWorkspaceId:
                          session.activeMembership?.workspace.id,
                      shrinkWrap: true,
                      currentSelectionId: _selectedWorkspace?.workspace.id,
                      onSelected: (membership) =>
                          setState(() => _selectedWorkspace = membership),
                    ),
                    const Divider(),
                  ],
                  if (memberships.isEmpty)
                    const EaseHint(
                      icon: Icons.apartment_outlined,
                      message: 'Create a workspace for your team, or accept an invitation sent by a manager.',
                    ),
                  const SizedBox(height: AppSpacing.m),
                  WorkspaceAccessLink(
                    icon: Icons.mail_outline,
                    title: 'Pending invitations',
                    subtitle: 'Invitations for your account',
                    onTap: state.busy
                        ? null
                        : () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute<({String id, bool accept})>(
                                builder: (_) => WorkspaceInvitationListScreen(
                                  invitations: state.invitations,
                                ),
                              ),
                            );
                            if (mounted && result != null) {
                              await _respondToInvitation(
                                result.id,
                                accept: result.accept,
                              );
                            }
                          },
                  ),
                  const SizedBox(height: 12),
                  WorkspaceAccessLink(
                    key: const Key('invitation-code-expander'),
                    icon: Icons.key_outlined,
                    title: 'Join with a token',
                    subtitle: 'Use your one-time invitation',
                    onTap: state.busy ? null : _acceptInvitation,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    key: const Key('create-workspace'),
                    onPressed: state.busy ? null : _createWorkspace,
                    icon: const Icon(Icons.add_business_outlined),
                    label: Text(context.tr('Create workspace')),
                  ),
                  if (state.loading) const AppContentLoading(rows: 2),
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
