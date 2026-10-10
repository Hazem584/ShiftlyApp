import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/auth/presentation/widgets/workspace_membership_chooser.dart';

Future<void> showWorkspaceSwitcher(
  BuildContext context, {
  ValueChanged<bool>? onSwitchingChanged,
}) async {
  final coordinator = context.read<SessionCoordinator>();
  final memberships = coordinator.selectableMemberships;
  final currentId = coordinator.state.activeMembership?.workspace.id;
  String? switchingId;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Text(
                context.tr('Switch workspace'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .65,
              ),
              child: WorkspaceMembershipChooser(
                memberships: memberships,
                currentWorkspaceId: currentId,
                switchingWorkspaceId: switchingId,
                shrinkWrap: true,
                onSelected: (membership) async {
                  if (switchingId != null) return;
                  setSheetState(() => switchingId = membership.workspace.id);
                  onSwitchingChanged?.call(true);
                  final result = await coordinator.switchWorkspace(
                    membership.workspace.id,
                  );
                  if (!context.mounted) return;
                  onSwitchingChanged?.call(false);
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                  if (result == WorkspaceSwitchResult.failure) {
                    ToastService.error(
                      context,
                      message: 'Unable to switch workspace. Please retry.',
                    );
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: OutlinedButton.icon(
                key: const Key('manage-workspace-invitations'),
                icon: const Icon(Icons.mark_email_unread_outlined),
                label: Text(context.tr('Workspaces and invitations')),
                onPressed: switchingId != null
                    ? null
                    : () {
                        Navigator.of(sheetContext).pop();
                        context.push('/workspaces');
                      },
              ),
            ),
          ],
        ),
      ),
    ),
  );
  if (context.mounted) onSwitchingChanged?.call(false);
}
