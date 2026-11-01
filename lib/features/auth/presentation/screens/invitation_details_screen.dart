import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/invitations/domain/repositories/invitation_repository.dart';
import 'package:shiftly/features/workspaces/domain/repositories/workspace_repository.dart';
import 'package:shiftly/features/workspaces/presentation/cubit/workspaces_cubit.dart';

import '../design/access_action.dart';
import '../design/access_notice.dart';
import '../design/access_page.dart';
import '../design/access_tile.dart';

class InvitationDetailsScreen extends StatefulWidget {
  const InvitationDetailsScreen({required this.invitation, super.key});
  final WorkspaceInvitation invitation;
  @override
  State<InvitationDetailsScreen> createState() =>
      _InvitationDetailsScreenState();
}

class _InvitationDetailsScreenState extends State<InvitationDetailsScreen> {
  Future<void> _respond(bool accept) async {
    final cubit = context.read<WorkspacesCubit>();
    if (cubit.state.busy) return;
    final user = context.read<SessionCoordinator>().state.currentUser?.id;
    final success = accept
        ? await cubit.acceptById(widget.invitation.id)
        : await cubit.decline(widget.invitation.id);
    if (!mounted ||
        !success ||
        context.read<SessionCoordinator>().state.currentUser?.id != user) {
      return;
    }
    Navigator.pop(context, accept ? 'accepted' : 'declined');
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<WorkspacesCubit, WorkspacesState>(
    builder: (context, state) {
      final invite = widget.invitation;
      final expired = invite.expiresAt?.isBefore(DateTime.now()) ?? false;
      final pending = invite.status == InvitationStatus.pending && !expired;
      final role = context.tr(
        invite.role == WorkspaceAccessRole.manager ? 'Manager' : 'Employee',
      );
      final format = DateFormat.yMMMd(
        Localizations.localeOf(context).languageCode,
      );
      return AccessPage(
        title: 'Invitation details',
        onBack: state.busy ? null : () => Navigator.pop(context),
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AccessAction(
              actionKey: Key('accept-invitation-${invite.id}'),
              label: context.tr('Accept invitation'),
              busy: state.accepting,
              onPressed: state.busy || !pending ? null : () => _respond(true),
            ),
            TextButton(
              key: Key('decline-invitation-${invite.id}'),
              onPressed: state.busy || !pending ? null : () => _respond(false),
              child: Text(
                context.tr(
                  state.declining ? 'Declining…' : 'Decline invitation',
                ),
              ),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AccessTile(
              title:
                  invite.workspace?.name ?? context.tr('Workspace invitation'),
              subtitle: [
                role,
                if (invite.jobTitle != null) invite.jobTitle!,
              ].join(' · '),
            ),
            const SizedBox(height: 12),
            AccessTile(
              icon: 'clock',
              title: invite.expiresAt == null
                  ? context.tr('Invitation details')
                  : context.tr('Expires {date}', {
                      'date': format.format(invite.expiresAt!.toLocal()),
                    }),
              subtitle: invite.createdAt == null
                  ? invite.email ?? ''
                  : context.tr('Sent {date}', {
                      'date': format.format(invite.createdAt!.toLocal()),
                    }),
            ),
            const SizedBox(height: 12),
            AccessNotice(
              pending
                  ? 'Accept to join this workspace with the role shown above.'
                  : 'This invitation is no longer available.',
              error: !pending,
            ),
            if (state.failure != null) ...[
              const SizedBox(height: 16),
              AccessNotice('', failure: state.failure),
            ],
          ],
        ),
      );
    },
  );
}
