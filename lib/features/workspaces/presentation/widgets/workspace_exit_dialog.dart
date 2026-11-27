import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class WorkspaceExitDialog extends StatefulWidget {
  const WorkspaceExitDialog({
    required this.workspaceName,
    required this.manager,
    super.key,
  });
  final String workspaceName;
  final bool manager;
  @override
  State<WorkspaceExitDialog> createState() => _WorkspaceExitDialogState();
}

class _WorkspaceExitDialogState extends State<WorkspaceExitDialog> {
  final confirmation = TextEditingController();
  @override
  void dispose() {
    confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.manager, name = widget.workspaceName;
    return AlertDialog(
      title: Text(
        context.tr(m ? 'Delete workspace for everyone' : 'Leave workspace'),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(
                m
                    ? 'This permanently deletes this workspace, its chats, files, tasks and attendance for every member. Their accounts and other workspaces stay available.'
                    : 'You will lose access to this workspace and its chats. Any running attendance will be clocked out. You can return only with a new invitation.',
              ),
            ),
            if (m) ...[
              const SizedBox(height: 16),
              Text(context.tr('Type {name} to confirm', {'name': name})),
              TextField(
                key: const Key('workspace-delete-confirmation'),
                controller: confirmation,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: context.tr('Workspace name'),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('Cancel')),
        ),
        FilledButton(
          key: const Key('confirm-leave-workspace'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: m && confirmation.text != name
              ? null
              : () => Navigator.pop(context, m ? confirmation.text : ''),
          child: Text(context.tr(m ? 'Permanently delete' : 'Leave workspace')),
        ),
      ],
    );
  }
}
