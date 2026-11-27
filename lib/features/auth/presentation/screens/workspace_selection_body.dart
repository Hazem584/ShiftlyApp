import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/core/widgets/ease_hint.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/auth/presentation/screens/workspace_invitation_list_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/workspace_selection_actions.dart';
import 'package:shiftly/features/auth/presentation/widgets/workspace_access_link.dart';
import 'package:shiftly/features/auth/presentation/widgets/workspace_membership_chooser.dart';
import 'package:shiftly/features/workspaces/presentation/cubit/workspaces_cubit.dart';

Widget buildWorkspaceSelectionBody(
  BuildContext context, {
  required List<WorkspaceMembership> memberships,
  required String? activeWorkspaceId,
  required String? selectedWorkspaceId,
  required ValueChanged<WorkspaceMembership> onSelect,
}) => BlocBuilder<WorkspacesCubit, WorkspacesState>(
  builder: (context, state) => ListView(
    key: Key(
      memberships.isEmpty ? 'no-workspace-onboarding' : 'workspace-access',
    ),
    padding: const EdgeInsets.all(AppSpacing.m),
    children: [
      Text(context.tr('Your role belongs to each workspace.')),
      const SizedBox(height: 16),
      if (memberships.isNotEmpty) ...[
        WorkspaceMembershipChooser(
          memberships: memberships,
          currentWorkspaceId: activeWorkspaceId,
          shrinkWrap: true,
          currentSelectionId: selectedWorkspaceId,
          onSelected: onSelect,
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
                final res = await Navigator.of(context).push(
                  MaterialPageRoute<({String id, bool accept})>(
                    builder: (_) => WorkspaceInvitationListScreen(
                      invitations: state.invitations,
                    ),
                  ),
                );
                if (context.mounted && res != null) {
                  await respondToWorkspaceInvitation(
                    context,
                    res.id,
                    accept: res.accept,
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
        onTap: state.busy ? null : () => promptAcceptInvitationToken(context),
      ),
      const SizedBox(height: 24),
      FilledButton.icon(
        key: const Key('create-workspace'),
        onPressed: state.busy ? null : () => promptCreateWorkspace(context),
        icon: const Icon(Icons.add_business_outlined),
        label: Text(context.tr('Create workspace')),
      ),
      if (state.loading) const AppContentLoading(rows: 2),
      if (state.failure != null) ...[
        const SizedBox(height: AppSpacing.m),
        Text(context.tr(state.failure!.message), textAlign: TextAlign.center),
        TextButton(
          onPressed: context.read<WorkspacesCubit>().load,
          child: Text(context.tr('Retry')),
        ),
      ],
    ],
  ),
);
