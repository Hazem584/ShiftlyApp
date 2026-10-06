part of '../../chat_screen.dart';

class _EditChatGroupDialogState extends State<_EditChatGroupDialog> {
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
  Widget build(BuildContext context) =>
      BlocConsumer<ChatGroupsCubit, ChatGroupsState>(
        bloc: widget.groups,
        listenWhen: (_, _) => widget.groups.scope != _scope,
        listener: (context, _) => _close(context),
        buildWhen: (before, after) => before.mutating != after.mutating,
        builder: (context, groupState) {
          final submitting = groupState.mutating;
          return AlertDialog(
            title: const Text('Edit group'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const Key('edit-group-name'),
                  controller: _name,
                  maxLength: 80,
                  enabled: !submitting,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  key: const Key('edit-group-description'),
                  controller: _description,
                  maxLength: 500,
                  enabled: !submitting,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
            actions: [
              TextButton(
                key: const Key('edit-group-cancel'),
                onPressed: submitting ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                key: const Key('edit-group-submit'),
                onPressed: submitting ? null : () => _submit(context),
                child: submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
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
      Fluttertoast.showToast(
        msg: widget.groups.state.failure?.message ?? 'Could not update group.',
      );
    }
  }

  void _close(BuildContext context) {
    if (_closing) return;
    _closing = true;
    Navigator.pop(context);
  }
}
