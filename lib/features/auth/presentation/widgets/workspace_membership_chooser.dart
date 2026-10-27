import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';

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
  final String? currentWorkspaceId;
  final String? currentSelectionId;
  final String? switchingWorkspaceId;
  final ValueChanged<WorkspaceMembership> onSelected;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) => ListView.separated(
    key: const Key('workspace-membership-chooser'),
    shrinkWrap: shrinkWrap,
    physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
    padding: const EdgeInsets.all(AppSpacing.m),
    itemCount: memberships.length,
    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s),
    itemBuilder: (context, index) {
      final membership = memberships[index];
      final current = membership.workspace.id == currentWorkspaceId;
      final selected =
          membership.workspace.id == (currentSelectionId ?? currentWorkspaceId);
      final switching = membership.workspace.id == switchingWorkspaceId;
      return Card(
        color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
        child: ListTile(
          key: Key('workspace-${membership.workspace.id}'),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.business_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          title: Text(
            membership.workspace.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            membership.role == WorkspaceRole.manager
                ? context.tr('Manager')
                : context.tr('Employee'),
          ),
          trailing: switching
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : current
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 20),
                    const SizedBox(width: 4),
                    Text(context.tr('Current')),
                  ],
                )
              : const Icon(Icons.chevron_right_rounded),
          onTap:
              (current && currentSelectionId == null) ||
                  switchingWorkspaceId != null
              ? null
              : () => onSelected(membership),
        ),
      );
    },
  );
}
