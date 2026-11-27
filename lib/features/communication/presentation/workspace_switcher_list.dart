import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/auth/domain/entities/workspace_membership.dart';

Widget buildWorkspaceSwitcherFooter(
  BuildContext context, {
  required bool busy,
  required bool canApply,
  required VoidCallback onApply,
}) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    FilledButton(
      key: const Key('apply-workspace-switch'),
      onPressed: !busy && canApply ? onApply : null,
      child: Text(
        context.tr(busy ? 'Switching workspace…' : 'Switch workspace'),
      ),
    ),
    TextButton(
      key: const Key('manage-workspace-invitations'),
      onPressed: busy
          ? null
          : () {
              Navigator.pop(context);
              context.push('/workspaces');
            },
      child: Text(context.tr('Workspaces and invitations')),
    ),
  ],
);

Widget buildWorkspaceMembershipList(
  BuildContext context, {
  required List<WorkspaceMembership> memberships,
  required String? selected,
  required String? current,
  required bool busy,
  required String? error,
  required ValueChanged<String> onSelect,
}) => ListView(
  key: const Key('workspace-membership-chooser'),
  padding: const EdgeInsets.all(24),
  children: [
    for (final member in memberships) ...[
      Card(
        child: ListTile(
          key: ValueKey('workspace-${member.workspace.id}'),
          leading: Icon(
            (selected ?? current) == member.workspace.id
                ? Icons.check_circle_outline
                : Icons.business_outlined,
          ),
          title: Text(member.workspace.name),
          subtitle: Text(
            '${context.tr(member.role.name == 'manager' ? 'Manager' : 'Employee')}${member.workspace.id == current ? ' · ${context.tr('Currently active')}' : ''}',
          ),
          selected: (selected ?? current) == member.workspace.id,
          onTap: busy ? null : () => onSelect(member.workspace.id),
        ),
      ),
      const SizedBox(height: 12),
    ],
    const SizedBox(height: 12),
    Text(
      context.tr(
        'Switching loads the selected workspace and its permissions.',
      ),
    ),
    if (error != null)
      Text(
        context.tr(error),
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
  ],
);
