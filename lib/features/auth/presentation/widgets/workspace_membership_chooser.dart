import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';

import '../design/access_tile.dart';

class WorkspaceMembershipChooser extends StatelessWidget {
  const WorkspaceMembershipChooser({
    required this.memberships,
    required this.onSelected,
    this.currentWorkspaceId,
    this.currentSelectionId,
    this.switchingWorkspaceId,
    this.shrinkWrap = false,
    super.key,
  });
  final List<WorkspaceMembership> memberships;
  final String? currentWorkspaceId, currentSelectionId, switchingWorkspaceId;
  final ValueChanged<WorkspaceMembership> onSelected;
  final bool shrinkWrap;
  @override
  Widget build(BuildContext context) => ListView.separated(
    key: const Key('workspace-membership-chooser'),
    shrinkWrap: shrinkWrap,
    physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
    padding: EdgeInsets.zero,
    itemCount: memberships.length,
    separatorBuilder: (_, _) => const SizedBox(height: 12),
    itemBuilder: (context, index) {
      final m = memberships[index];
      final current = m.workspace.id == currentWorkspaceId;
      final selected =
          m.workspace.id == (currentSelectionId ?? currentWorkspaceId);
      final switching = m.workspace.id == switchingWorkspaceId;
      return Padding(
        padding: EdgeInsets.only(
          bottom: index == memberships.length - 1 ? 12 : 0,
        ),
        child: AccessTile(
          key: Key('workspace-${m.workspace.id}'),
          title: m.workspace.name,
          subtitle: context.tr(
            m.role == WorkspaceRole.manager ? 'Manager' : 'Employee',
          ),
          selected: selected,
          trailing: switching
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : current
              ? Text(
                  context.tr('Current'),
                  style: Theme.of(context).textTheme.bodySmall,
                )
              : null,
          onTap:
              (current && currentSelectionId == null) ||
                  switchingWorkspaceId != null
              ? null
              : () => onSelected(m),
        ),
      );
    },
  );
}
