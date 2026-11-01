import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/workspaces/presentation/cubit/workspaces_cubit.dart';

import '../design/access_action.dart';
import '../design/access_notice.dart';
import '../design/access_page.dart';
import '../design/access_tile.dart';
import '../widgets/access_navigation.dart';
import 'invitation_details_screen.dart';

class MyInvitationsScreen extends StatelessWidget {
  const MyInvitationsScreen({super.key});
  Future<void> _view(BuildContext context, Widget screen) async {
    final result = await pushAccess<String>(context, screen);
    if (!context.mounted) return;
    if (result == 'accepted') {
      Navigator.pop(context, true);
    }
    if (result == 'declined') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Invitation declined.'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<WorkspacesCubit, WorkspacesState>(
        builder: (context, state) => AccessPage(
          title: 'My invitations',
          onBack: () => Navigator.pop(context),
          footer: state.invitations.isEmpty
              ? null
              : AccessAction(
                  label: context.tr('View invitation'),
                  onPressed: state.busy
                      ? null
                      : () => _view(
                          context,
                          InvitationDetailsScreen(
                            invitation: state.invitations.first,
                          ),
                        ),
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.loading) const LinearProgressIndicator(),
              if (!state.loading && state.invitations.isEmpty)
                const AccessNotice('No invitations waiting for you.'),
              for (final invite in state.invitations) ...[
                AccessTile(
                  key: Key('view-invitation-${invite.id}'),
                  title:
                      invite.workspace?.name ??
                      context.tr('Workspace invitation'),
                  subtitle: [
                    context.tr(
                      invite.role.name == 'manager' ? 'Manager' : 'Employee',
                    ),
                    if (invite.jobTitle != null) invite.jobTitle!,
                  ].join(' · '),
                  onTap: state.busy
                      ? null
                      : () => _view(
                          context,
                          InvitationDetailsScreen(invitation: invite),
                        ),
                ),
                const SizedBox(height: 12),
              ],
              const AccessNotice(
                'Invitations are linked to your signed-in email. Check the details before joining.',
              ),
              if (state.failure != null) ...[
                const SizedBox(height: 16),
                AccessNotice('', failure: state.failure),
              ],
              TextButton(
                onPressed: state.loading
                    ? null
                    : context.read<WorkspacesCubit>().load,
                child: Text(context.tr('Refresh')),
              ),
            ],
          ),
        ),
      );
}
