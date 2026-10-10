import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/invitations/domain/repositories/invitation_repository.dart';

class WorkspaceInvitationCard extends StatelessWidget {
  const WorkspaceInvitationCard({
    super.key,
    required this.invitation,
    required this.disabled,
    required this.accepting,
    required this.declining,
    required this.onAccept,
    required this.onDecline,
  });
  final WorkspaceInvitation invitation;
  final bool disabled, accepting, declining;
  final VoidCallback onAccept, onDecline;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: SurfaceCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final details = Row(
            children: [
              const Icon(Icons.apartment_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invitation.workspace?.name ??
                          context.tr('Workspace invitation'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      invitation.jobTitle ?? context.tr('Employee'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                key: Key('accept-invitation-${invitation.id}'),
                onPressed: disabled ? null : onAccept,
                icon: accepting
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(context.tr('Accept')),
              ),
              OutlinedButton.icon(
                key: Key('decline-invitation-${invitation.id}'),
                onPressed: disabled ? null : onDecline,
                icon: declining
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.close_rounded),
                label: Text(context.tr('Decline')),
              ),
            ],
          );
          if (constraints.maxWidth >= 600 &&
              MediaQuery.textScalerOf(context).scale(1) <= 1.3) {
            return Row(
              children: [
                Expanded(child: details),
                const SizedBox(width: 16),
                actions,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [details, const SizedBox(height: 14), actions],
          );
        },
      ),
    ),
  );
}
