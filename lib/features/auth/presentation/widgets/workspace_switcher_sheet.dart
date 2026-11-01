import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';

import 'workspace_membership_chooser.dart';

class WorkspaceSwitcherSheet extends StatefulWidget {
  const WorkspaceSwitcherSheet({
    required this.coordinator,
    this.onSwitchingChanged,
    super.key,
  });
  final SessionCoordinator coordinator;
  final ValueChanged<bool>? onSwitchingChanged;
  @override
  State<WorkspaceSwitcherSheet> createState() => _WorkspaceSwitcherSheetState();
}

class _WorkspaceSwitcherSheetState extends State<WorkspaceSwitcherSheet> {
  String? _switching;
  String? _error;
  Future<void> _select(WorkspaceMembership membership) async {
    if (_switching != null) return;
    setState(() {
      _switching = membership.workspace.id;
      _error = null;
    });
    widget.onSwitchingChanged?.call(true);
    final result = await widget.coordinator.switchWorkspace(
      membership.workspace.id,
    );
    widget.onSwitchingChanged?.call(false);
    if (!mounted) return;
    if (result == WorkspaceSwitchResult.failure) {
      setState(() {
        _switching = null;
        _error = 'Unable to switch workspace. Please retry.';
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .8,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('Switch workspace'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              WorkspaceMembershipChooser(
                memberships: widget.coordinator.selectableMemberships,
                currentWorkspaceId:
                    widget.coordinator.state.activeMembership?.workspace.id,
                switchingWorkspaceId: _switching,
                shrinkWrap: true,
                onSelected: _select,
              ),
              if (_error != null)
                Text(
                  context.tr(_error!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              OutlinedButton(
                key: const Key('manage-workspace-invitations'),
                onPressed: _switching != null
                    ? null
                    : () {
                        final router = GoRouter.of(context);
                        Navigator.pop(context);
                        router.push('/workspaces');
                      },
                child: Text(context.tr('Workspaces and invitations')),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
