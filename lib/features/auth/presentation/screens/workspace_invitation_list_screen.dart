import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/access_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/workspace_invitation_details_screen.dart';
import 'package:shiftly/features/auth/presentation/widgets/workspace_access_link.dart';
import 'package:shiftly/features/invitations/domain/repositories/invitation_repository.dart';

class WorkspaceInvitationListScreen extends StatelessWidget {
  const WorkspaceInvitationListScreen({required this.invitations, super.key});
  final List<WorkspaceInvitation> invitations;

  @override
  Widget build(BuildContext context) => AccessScreen(
    title: 'My invitations',
    children: [
      if (invitations.isEmpty) Text(context.tr('No pending invitations')),
      for (final invitation in invitations) ...[
        WorkspaceAccessLink(
          key: Key('open-invitation-${invitation.id}'),
          icon: Icons.apartment_outlined,
          title: invitation.workspace?.name ?? 'Workspace invitation',
          subtitle: invitation.jobTitle ?? 'Employee',
          onTap: () async {
            final accept = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) =>
                    WorkspaceInvitationDetailsScreen(invitation: invitation),
              ),
            );
            if (accept != null && context.mounted) {
              Navigator.of(context).pop((id: invitation.id, accept: accept));
            }
          },
        ),
        const SizedBox(height: 12),
      ],
      Text(context.tr('Invitations are linked to your signed-in email.')),
    ],
  );
}
