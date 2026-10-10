import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/app_form_dialog.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';

class EditChatGroupDialog extends StatefulWidget {
  const EditChatGroupDialog({
    super.key,
    required this.group,
    required this.groups,
    required this.onSuccess,
  });

  final ChatGroup group;
  final ChatGroupsCubit groups;
  final VoidCallback onSuccess;

  @override
  State<EditChatGroupDialog> createState() => _EditChatGroupDialogState();
}

class _EditChatGroupDialogState extends State<EditChatGroupDialog> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final Object? _scope;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.group.name);
    _description = TextEditingController(text: widget.group.description);
    _scope = widget.groups.scope;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<ChatGroupsCubit, ChatGroupsState>(
    bloc: widget.groups,
    listenWhen: (_, _) => widget.groups.scope != _scope,
    listener: (context, _) => _close(context),
    buildWhen: (before, after) => before.mutating != after.mutating,
    builder: (context, groupState) {
      final submitting = groupState.mutating;
      return AppFormDialog(
        title: context.tr('Edit group'),
        subtitle: context.tr('Update the name and description your team sees.'),
        icon: Icons.edit_outlined,
        busy: submitting,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('edit-group-name'),
              controller: _name,
              maxLength: 80,
              enabled: !submitting,
              decoration: InputDecoration(labelText: context.tr('Name')),
            ),
            TextField(
              key: const Key('edit-group-description'),
              controller: _description,
              maxLength: 500,
              enabled: !submitting,
              decoration: InputDecoration(labelText: context.tr('Description')),
            ),
          ],
        ),
        actions: [
          TextButton(
            key: const Key('edit-group-cancel'),
            onPressed: submitting ? null : () => Navigator.pop(context),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            key: const Key('edit-group-submit'),
            onPressed: submitting ? null : () => _submit(context),
            child: submitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.tr('Save')),
          ),
        ],
      );
    },
  );

  Future<void> _submit(BuildContext context) async {
    final name = _name.text.trim();
    final description = _description.text.trim();
    if (name.isEmpty) {
      if (!mounted) return;
      Fluttertoast.showToast(msg: context.tr('Enter a group name.'));
      return;
    }
    if (name.length > 80 || description.length > 500) {
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: context.tr('Check the group name and description lengths.'),
      );
      return;
    }
    if (widget.groups.scope != _scope) {
      if (context.mounted) _close(context);
      return;
    }
    final result = await widget.groups.update(
      widget.group.id,
      name: name,
      description: description,
    );
    if (!context.mounted) return;
    if (result == ChatMutationResult.success) {
      _close(context);
      widget.onSuccess();
    } else if (result == ChatMutationResult.stale ||
        widget.groups.scope != _scope) {
      _close(context);
    } else if (result == ChatMutationResult.failure) {
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: context.tr(
          widget.groups.state.failure?.message ?? 'Could not update group.',
        ),
      );
    }
  }

  void _close(BuildContext context) {
    if (_closing) return;
    _closing = true;
    Navigator.pop(context);
  }
}
