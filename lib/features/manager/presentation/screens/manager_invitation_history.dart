import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/invitations/domain/repositories/invitation_repository.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/presentation/cubit/work_feed_cubit.dart';
import 'package:shiftly/features/team_work/presentation/widgets/work_feed_view.dart';

class ManagerInvitationHistory extends StatefulWidget {
  const ManagerInvitationHistory({required this.workspaceId, super.key});
  final String workspaceId;
  @override
  State<ManagerInvitationHistory> createState() =>
      _ManagerInvitationHistoryState();
}

class _ManagerInvitationHistoryState extends State<ManagerInvitationHistory> {
  late final WorkFeedCubit<WorkspaceInvitation> _feed;
  InvitationStatus? _status;
  @override
  void initState() {
    super.initState();
    final workspaceId = widget.workspaceId;
    _feed = WorkFeedCubit((_) async {
      final items = await context
          .read<InvitationRepository>()
          .listWorkspaceInvitations(workspaceId: workspaceId, status: _status);
      return WorkPage(items, items.length);
    })..load();
  }

  @override
  void dispose() {
    _feed.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membership = context
        .watch<SessionCoordinator?>()
        ?.state
        .activeMembership;
    if (membership != null && membership.workspace.id != widget.workspaceId) {
      return const SizedBox.shrink();
    }
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Invitation history'))),
      body: WorkFeedView<WorkspaceInvitation>(
        cubit: _feed,
        header: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in <(InvitationStatus?, String)>[
              (null, 'All'),
              (InvitationStatus.pending, 'Pending'),
              (InvitationStatus.accepted, 'Accepted'),
              (InvitationStatus.expired, 'Expired'),
              (InvitationStatus.revoked, 'Revoked'),
            ])
              ChoiceChip(
                label: Text(context.tr(item.$2)),
                selected: _status == item.$1,
                onSelected: (_) {
                  setState(() => _status = item.$1);
                  _feed.load();
                },
              ),
          ],
        ),
        itemBuilder: (context, invitation, busy) => SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                invitation.email ?? context.tr('Invitation'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (invitation.jobTitle != null) ...[
                const SizedBox(height: 8),
                Text(invitation.jobTitle!),
              ],
              const SizedBox(height: 8),
              Text(
                context.tr(switch (invitation.status) {
                  InvitationStatus.pending => 'Pending',
                  InvitationStatus.accepted => 'Accepted',
                  InvitationStatus.revoked => 'Revoked',
                  InvitationStatus.expired => 'Expired',
                  _ => 'Unknown',
                }),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (invitation.expiresAt != null)
                Text(
                  context.tr('Expires {date}', {
                    'date': MaterialLocalizations.of(context)
                        .formatMediumDate(invitation.expiresAt!.toLocal()),
                  }),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
