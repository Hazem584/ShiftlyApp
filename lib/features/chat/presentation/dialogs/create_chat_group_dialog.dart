import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/widgets/app_form_dialog.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';

class CreateChatGroupDialog extends StatefulWidget {
  const CreateChatGroupDialog({
    super.key,
    required this.cubit,
    required this.scope,
    required this.employees,
  });

  final ChatGroupsCubit cubit;
  final FeatureSessionScope scope;
  final List<Employee> employees;

  @override
  State<CreateChatGroupDialog> createState() => _CreateChatGroupDialogState();
}

class _CreateChatGroupDialogState extends State<CreateChatGroupDialog> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _selected = <String>{};
  bool _closing = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<ChatGroupsCubit, ChatGroupsState>(
        bloc: widget.cubit,
        listenWhen: (_, _) => widget.cubit.scope != widget.scope,
        listener: (context, _) => _close(context),
        buildWhen: (before, after) => before.mutating != after.mutating,
        builder: (context, groupState) {
          final submitting = groupState.mutating;
          return AppFormDialog(
            title: 'Create chat group',
            subtitle:
                'Give your team a space to plan shifts and stay in touch.',
            icon: Icons.group_add_outlined,
            busy: submitting,
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      key: const Key('create-group-name'),
                      controller: _name,
                      maxLength: 80,
                      enabled: !submitting,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Group name',
                        hintText: 'e.g. Evening team',
                      ),
                    ),
                    TextField(
                      key: const Key('create-group-description'),
                      controller: _description,
                      maxLength: 500,
                      enabled: !submitting,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'What is this group for?',
                        helperText: 'Optional',
                      ),
                    ),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Members'),
                    ),
                    if (widget.employees.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'No active employees are available. The manager will be included.',
                        ),
                      ),
                    for (final employee in widget.employees)
                      CheckboxListTile(
                        key: Key('create-group-member-${employee.id}'),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _selected.contains(employee.id),
                        title: Text(employee.displayName),
                        subtitle: Text(
                          employee.displayEmail,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onChanged: submitting
                            ? null
                            : (value) => setState(
                                () => value == true
                                    ? _selected.add(employee.id)
                                    : _selected.remove(employee.id),
                              ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                key: const Key('create-group-cancel'),
                onPressed: submitting ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                key: const Key('create-group-submit'),
                onPressed: submitting ? null : () => _submit(context),
                child: submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create'),
              ),
            ],
          );
        },
      );

  Future<void> _submit(BuildContext context) async {
    final name = _name.text.trim();
    final description = _description.text.trim();
    if (name.isEmpty) {
      Fluttertoast.showToast(msg: 'Enter a group name.');
      return;
    }
    if (name.length > 80 || description.length > 500) {
      Fluttertoast.showToast(
        msg: 'Check the group name and description lengths.',
      );
      return;
    }
    if (widget.cubit.scope != widget.scope) {
      if (context.mounted) _close(context);
      return;
    }
    final result = await widget.cubit.create(
      name: name,
      description: description,
      membershipIds: _selected.toList(),
    );
    if (!context.mounted) return;
    if (result == ChatMutationResult.success ||
        result == ChatMutationResult.stale ||
        widget.cubit.scope != widget.scope) {
      _close(context);
    } else if (result == ChatMutationResult.failure) {
      Fluttertoast.showToast(
        msg: widget.cubit.state.failure?.message ?? 'Could not create group.',
      );
    }
  }

  void _close(BuildContext context) {
    if (_closing) return;
    _closing = true;
    Navigator.pop(context);
  }
}
