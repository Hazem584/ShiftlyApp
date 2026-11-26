import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/access_screen.dart';
import 'package:shiftly/features/auth/presentation/widgets/workspace_invitation_card.dart';
import 'package:shiftly/features/invitations/domain/repositories/invitation_repository.dart';

class WorkspaceInvitationDetailsScreen extends StatelessWidget {
  const WorkspaceInvitationDetailsScreen({required this.invitation, super.key});
  final WorkspaceInvitation invitation;

  @override
  Widget build(BuildContext context) {
    final date = MaterialLocalizations.of(context).formatMediumDate;
    final expires = invitation.expiresAt;
    return AccessScreen(
      title: 'Invitation details',
      actions: [
        WorkspaceInvitationCard(
          invitation: invitation,
          disabled: false,
          accepting: false,
          declining: false,
          onAccept: () => Navigator.of(context).pop(true),
          onDecline: () => Navigator.of(context).pop(false),
        ),
      ],
      children: [
        Text(
          invitation.workspace?.name ?? context.tr('Workspace invitation'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          [
            context.tr(
              invitation.role.name == 'manager' ? 'Manager' : 'Employee',
            ),
            ?invitation.jobTitle,
          ].join(' · '),
        ),
        if (expires != null) ...[
          const SizedBox(height: 16),
          Text(context.tr('Expires {date}', {'date': date(expires.toLocal())})),
        ],
        const SizedBox(height: 16),
        Text(
          context.tr(
            'Accept to join this workspace with the role shown above.',
          ),
        ),
      ],
    );
  }
}
