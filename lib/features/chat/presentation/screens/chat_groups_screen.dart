import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/routing/app_routes.dart';
import 'package:shiftly/features/chat/data/chat_member_loader.dart';
import 'package:shiftly/features/chat/data/chat_models.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/chat/presentation/screens/chat_screen.dart';
import 'package:shiftly/features/employees/data/employee_repository.dart';

class ChatGroupsScreen extends StatelessWidget {
  const ChatGroupsScreen({this.embedded = false, super.key});
  final bool embedded;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ChatGroupsCubit, ChatGroupsState>(
        builder: (context, state) {
          final cubit = context.read<ChatGroupsCubit>();
          final manager = cubit.scope?.isManager == true;
          final content = _body(context, state);
          if (embedded) return content;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Chat'),
              actions: [
                IconButton(
                  tooltip: 'Refresh chat',
                  onPressed: state.refreshing
                      ? null
                      : () => cubit.load(refresh: true),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            floatingActionButton: manager
                ? FloatingActionButton.extended(
                    key: const Key('create-chat-group'),
                    onPressed: state.mutating
                        ? null
                        : () => _showCreate(context),
                    icon: const Icon(Icons.add_comment_outlined),
                    label: const Text('New group'),
                  )
                : null,
            body: content,
          );
        },
      );

  Widget _body(BuildContext context, ChatGroupsState state) {
    if (state.loading) return const Center(child: CircularProgressIndicator());
    if (state.groups.isEmpty && state.failure != null) {
      return _MessageState(
        message: state.failure!.message,
        action: () => context.read<ChatGroupsCubit>().load(),
      );
    }
    if (state.groups.isEmpty) {
      return const _MessageState(message: 'No chat groups yet.');
    }
    return Column(
      children: [
        if (state.failure != null)
          MaterialBanner(
            content: Text(state.failure!.message),
            actions: [
              TextButton(
                onPressed: () =>
                    context.read<ChatGroupsCubit>().load(refresh: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                context.read<ChatGroupsCubit>().load(refresh: true),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 360;
                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    narrow ? 8 : 16,
                    8,
                    narrow ? 8 : 16,
                    96,
                  ),
                  itemCount: state.groups.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _GroupTile(
                    group: state.groups[index],
                    narrow: narrow,
                    onTap: () =>
                        context.read<ChatGroupsCubit>().scope?.isManager == true
                        ? context.push(
                            AppRoutes.chatGroup(state.groups[index].id),
                          )
                        : Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ChatScreen(groupId: state.groups[index].id),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showCreate(BuildContext context) async {
    final cubit = context.read<ChatGroupsCubit>();
    final scope = cubit.scope;
    if (scope == null) return;
    List<Employee> employees;
    try {
      employees = await loadActiveChatMembers(
        context.read<EmployeeRepository>(),
        scope,
      );
    } catch (_) {
      Fluttertoast.showToast(msg: 'Could not load active workspace members.');
      return;
    }
    if (!context.mounted || cubit.scope != scope) return;
    final name = TextEditingController();
    final description = TextEditingController();
    final selected = <String>{};
    final submit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create chat group'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    maxLength: 100,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    controller: description,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                    ),
                  ),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Members'),
                  ),
                  if (employees.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Load active employees first, then try again.',
                      ),
                    ),
                  for (final employee in employees)
                    CheckboxListTile(
                      dense: true,
                      value: selected.contains(employee.id),
                      title: Text(employee.displayName),
                      subtitle: Text(employee.displayEmail),
                      onChanged: (value) => setState(
                        () => value == true
                            ? selected.add(employee.id)
                            : selected.remove(employee.id),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    if (submit != true || !context.mounted) return;
    if (name.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: 'Enter a group name.');
      return;
    }
    final result = await context.read<ChatGroupsCubit>().create(
      name: name.text,
      description: description.text,
      membershipIds: selected.toList(),
    );
    if (result == ChatMutationResult.failure && context.mounted) {
      Fluttertoast.showToast(
        msg:
            context.read<ChatGroupsCubit>().state.failure?.message ??
            'Could not create group.',
      );
    }
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.group,
    required this.narrow,
    required this.onTap,
  });
  final ChatGroup group;
  final bool narrow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: narrow ? 10 : 16,
        vertical: 6,
      ),
      leading: CircleAvatar(
        child: Text(group.name.characters.first.toUpperCase()),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              group.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (group.isArchived)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.archive_outlined, size: 18),
            ),
        ],
      ),
      subtitle: Text(
        group.lastMessage?.text ?? '${group.memberCount} members',
        maxLines: narrow ? 1 : 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (group.lastMessage != null)
            Text(
              MaterialLocalizations.of(context).formatTimeOfDay(
                TimeOfDay.fromDateTime(group.lastMessage!.createdAt.toLocal()),
              ),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          if (group.unreadCount > 0)
            Badge(
              label: Text(
                group.unreadCount > 99 ? '99+' : '${group.unreadCount}',
              ),
            ),
        ],
      ),
    ),
  );
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message, this.action});
  final String message;
  final VoidCallback? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (action != null)
            TextButton(onPressed: action, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
