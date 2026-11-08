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
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      context.tr(
        widget.manager ? 'Delete workspace for everyone' : 'Leave workspace',
      ),
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(
              widget.manager
                  ? 'This permanently deletes this workspace, its chats, files, tasks and attendance for every member. Their accounts and other workspaces stay available.'
                  : 'You will lose access to this workspace and its chats. Any running attendance will be clocked out. You can return only with a new invitation.',
            ),
          ),
          if (widget.manager) ...[
            const SizedBox(height: 16),
            Text(
              context.tr('Type {name} to confirm', {
                'name': widget.workspaceName,
              }),
            ),
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
        onPressed: widget.manager && confirmation.text != widget.workspaceName
            ? null
            : () => Navigator.pop(
                context,
                widget.manager ? confirmation.text : '',
              ),
        child: Text(
          context.tr(widget.manager ? 'Permanently delete' : 'Leave workspace'),
        ),
      ),
    ],
  );
}
