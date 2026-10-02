import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/features/chat/data/chat_member_loader.dart';
import 'package:shiftly/features/chat/data/chat_models.dart';
import 'package:shiftly/features/chat/data/chat_realtime.dart';
import 'package:shiftly/features/chat/data/chat_repository.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_group_details_cubit.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/employees/data/employee_repository.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({required this.groupId, super.key});
  final String groupId;

  @override
  Widget build(BuildContext context) {
    final groups = context.read<ChatGroupsCubit>();
    final scope = groups.scope;
    if (scope == null) {
      return const Scaffold(
        body: Center(child: Text('Chat session is no longer active.')),
      );
    }
    final repository = context.read<ChatRepository>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ChatGroupDetailsCubit(
            repository,
            onChanged: () => groups.load(refresh: true),
          )..bind(scope, groupId),
        ),
        BlocProvider(
          create: (_) => ChatConversationCubit(
            repository,
            context.read<ChatRealtime>(),
            onChanged: () {
              groups.refreshUnread();
              groups.load(refresh: true);
            },
          )..bind(scope, groupId),
        ),
      ],
      child: const _ChatView(),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView();
  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  bool _loadingOlder = false;
  bool _initialPositioned = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() async {
    if (!_scroll.hasClients || _scroll.offset > 120 || _loadingOlder) return;
    final cubit = context.read<ChatConversationCubit>();
    if (!cubit.state.hasMore) return;
    _loadingOlder = true;
    final oldExtent = _scroll.position.maxScrollExtent;
    await cubit.loadOlder();
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          final added = _scroll.position.maxScrollExtent - oldExtent;
          _scroll.jumpTo(
            (_scroll.offset + added).clamp(0, _scroll.position.maxScrollExtent),
          );
        }
      });
    }
    _loadingOlder = false;
  }

  @override
  void dispose() {
    _scroll.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<ChatGroupDetailsCubit, ChatGroupDetailsState>(
    builder: (context, details) {
      final group = details.group;
      final manager = context.read<ChatGroupsCubit>().scope?.isManager == true;
      return Scaffold(
        appBar: AppBar(
          title: Text(group?.name ?? 'Chat'),
          actions: [
            IconButton(
              tooltip: 'Group members',
              onPressed: group == null ? null : () => _showMembers(group),
              icon: const Icon(Icons.group_outlined),
            ),
            if (manager && group != null && !group.isArchived)
              PopupMenuButton<String>(
                onSelected: (value) =>
                    value == 'edit' ? _edit(group) : _archive(group),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit group')),
                  PopupMenuItem(value: 'archive', child: Text('Archive group')),
                ],
              ),
          ],
        ),
        body: Column(
          children: [
            if (details.failure != null)
              MaterialBanner(
                content: Text(details.failure!.message),
                actions: [
                  TextButton(
                    onPressed: context.read<ChatGroupDetailsCubit>().load,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            if (group?.isArchived == true)
              const ColoredBox(
                color: Color(0xfffff3cd),
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.archive_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Archived group — read only'),
                    ],
                  ),
                ),
              ),
            Expanded(child: _messages()),
            _composer(disabled: group == null || group.isArchived),
          ],
        ),
      );
    },
  );

  Widget
  _messages() => BlocConsumer<ChatConversationCubit, ChatConversationState>(
    listenWhen: (before, after) =>
        after.messages.length > before.messages.length && !after.loadingOlder,
    listener: (_, state) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) return;
        if (!_initialPositioned) {
          _initialPositioned = true;
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        } else if (_scroll.position.maxScrollExtent - _scroll.offset < 500) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          );
        }
      });
    },
    builder: (context, state) {
      if (state.loading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (state.messages.isEmpty && state.failure != null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.failure!.message),
              TextButton(
                onPressed: context.read<ChatConversationCubit>().load,
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
      if (state.messages.isEmpty) {
        return const Center(
          child: Text('No messages yet. Start the conversation.'),
        );
      }
      final membershipId = context.read<ChatGroupsCubit>().scope!.membershipId;
      return RefreshIndicator(
        onRefresh: () =>
            context.read<ChatConversationCubit>().load(refresh: true),
        child: ListView.builder(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          itemCount: state.messages.length + (state.loadingOlder ? 1 : 0),
          itemBuilder: (_, index) {
            if (state.loadingOlder && index == 0) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final offset = state.loadingOlder ? index - 1 : index;
            final message = state.messages[offset];
            return _MessageBubble(
              message: message,
              mine: message.sender.membershipId == membershipId,
            );
          },
        ),
      );
    },
  );

  Widget _composer({required bool disabled}) => SafeArea(
    top: false,
    child: BlocBuilder<ChatConversationCubit, ChatConversationState>(
      builder: (context, state) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.failedText != null)
              Row(
                children: [
                  const Expanded(child: Text('Message failed to send.')),
                  TextButton(
                    onPressed: state.sending
                        ? null
                        : context.read<ChatConversationCubit>().retrySend,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('chat-message-input'),
                    controller: _text,
                    enabled: !disabled && !state.sending,
                    maxLength: 4000,
                    minLines: 1,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: disabled
                          ? 'This group is read only'
                          : 'Message',
                      counterText: '',
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(
                  key: const Key('send-chat-message'),
                  tooltip: 'Send',
                  onPressed: disabled || state.sending ? null : _send,
                  icon: state.sending
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    if (text.length > 4000) {
      Fluttertoast.showToast(
        msg: 'Messages can contain at most 4000 characters.',
      );
      return;
    }
    final sent = await context.read<ChatConversationCubit>().send(text);
    if (sent && mounted) _text.clear();
  }

  Future<void> _edit(ChatGroup group) async {
    final name = TextEditingController(text: group.name);
    final description = TextEditingController(text: group.description);
    final groups = context.read<ChatGroupsCubit>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setState) {
          final submitting = groups.state.mutating;
          return AlertDialog(
            title: const Text('Edit group'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  maxLength: 80,
                  enabled: !submitting,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: description,
                  maxLength: 500,
                  enabled: !submitting,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: submitting
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: submitting
                    ? null
                    : () async {
                        final trimmedName = name.text.trim();
                        final trimmedDescription = description.text.trim();
                        if (trimmedName.isEmpty) {
                          Fluttertoast.showToast(msg: 'Enter a group name.');
                          return;
                        }
                        setState(() {});
                        final result = await groups.update(
                          group.id,
                          name: trimmedName,
                          description: trimmedDescription,
                        );
                        if (!dialogContext.mounted) return;
                        if (result == ChatMutationResult.success) {
                          Navigator.pop(dialogContext);
                          if (mounted) {
                            context.read<ChatGroupDetailsCubit>().load();
                          }
                        } else {
                          setState(() {});
                          Fluttertoast.showToast(
                            msg:
                                groups.state.failure?.message ??
                                'Could not update group.',
                          );
                        }
                      },
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
      ),
    );
    name.dispose();
    description.dispose();
  }

  Future<void> _archive(ChatGroup group) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Archive group?'),
        content: const Text(
          'Messages remain readable, but no further changes or messages can be made.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final result = await context.read<ChatGroupsCubit>().archive(group.id);
    if (result == ChatMutationResult.success && mounted) {
      context.read<ChatGroupDetailsCubit>().load();
    }
  }

  Future<void> _showMembers(ChatGroup group) async {
    final manager = context.read<ChatGroupsCubit>().scope?.isManager == true;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<ChatGroupDetailsCubit>(),
        child: _MembersSheet(canManage: manager && !group.isArchived),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.mine});
  final ChatMessage message;
  final bool mine;
  @override
  Widget build(BuildContext context) => Align(
    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 520),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: mine
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!mine)
            Text(
              message.sender.displayName,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          Text(message.text),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              MaterialLocalizations.of(context).formatTimeOfDay(
                TimeOfDay.fromDateTime(message.createdAt.toLocal()),
              ),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    ),
  );
}

class _MembersSheet extends StatelessWidget {
  const _MembersSheet({required this.canManage});
  final bool canManage;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ChatGroupDetailsCubit, ChatGroupDetailsState>(
        builder: (context, state) {
          final group = state.group;
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
              ),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * .65,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Members',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        if (canManage && group != null)
                          IconButton(
                            onPressed: () => _add(context, group),
                            tooltip: 'Add members',
                            icon: const Icon(Icons.person_add_alt_1),
                          ),
                      ],
                    ),
                    if (state.mutating) const LinearProgressIndicator(),
                    Expanded(
                      child: group == null
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              itemCount: group.members.length,
                              itemBuilder: (_, index) {
                                final member = group.members[index];
                                return ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.person_outline),
                                  ),
                                  title: Text(member.displayName),
                                  subtitle: member.email == null
                                      ? null
                                      : Text(member.email!),
                                  trailing: canManage
                                      ? IconButton(
                                          tooltip: 'Remove member',
                                          onPressed: state.mutating
                                              ? null
                                              : () => _remove(context, member),
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                          ),
                                        )
                                      : null,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

  Future<void> _remove(BuildContext context, ChatMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text('${member.displayName} will lose access to this group.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<ChatGroupDetailsCubit>().removeMember(
        member.membershipId,
      );
    }
  }

  Future<void> _add(BuildContext context, ChatGroup group) async {
    final scope = context.read<ChatGroupsCubit>().scope;
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
    if (!context.mounted || context.read<ChatGroupsCubit>().scope != scope) {
      return;
    }
    final existing = group.members.map((m) => m.membershipId).toSet();
    final choices = employees.where((e) => !existing.contains(e.id)).toList();
    final selected = <String>{};
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: const Text('Add members'),
          content: SizedBox(
            width: 420,
            child: choices.isEmpty
                ? const Text('No other active workspace members are available.')
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final employee in choices)
                        CheckboxListTile(
                          value: selected.contains(employee.id),
                          title: Text(employee.displayName),
                          onChanged: (value) => setState(
                            () => value == true
                                ? selected.add(employee.id)
                                : selected.remove(employee.id),
                          ),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<ChatGroupDetailsCubit>().addMembers(selected.toList());
    }
  }
}
