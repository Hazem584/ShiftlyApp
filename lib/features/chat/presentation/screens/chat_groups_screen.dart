import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/routing/app_routes.dart';
import 'package:shiftly/core/theme/collaboration_appearance.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/features/chat/domain/usecases/load_active_chat_members.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/chat/presentation/dialogs/create_chat_group_dialog.dart';
import 'package:shiftly/features/chat/presentation/dialogs/shiftly_chat_dialog.dart';
import 'package:shiftly/features/chat/presentation/screens/chat_screen.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_group_tile.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_message_state.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';

class ChatGroupsScreen extends StatefulWidget {
  const ChatGroupsScreen({this.embedded = false, super.key});
  final bool embedded;
  @override
  State<ChatGroupsScreen> createState() => _ChatGroupsScreenState();
}

class _ChatGroupsScreenState extends State<ChatGroupsScreen> {
  bool _archived = false;
  @override
  Widget build(BuildContext context) =>
      CollaborationAppearance(child: Builder(builder: _build));
  Widget _build(BuildContext context) =>
      BlocBuilder<ChatGroupsCubit, ChatGroupsState>(
        builder: (context, state) {
          final cubit = context.read<ChatGroupsCubit>();
          final manager = cubit.scope?.isManager == true;
          final content = _body(context, state);

          return Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('Groups')),
                  Text(
                    cubit.scope?.workspaceName ?? context.tr('Chat'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: context.tr('Refresh chat'),
                  onPressed: state.refreshing
                      ? null
                      : () => cubit.load(refresh: true),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            bottomNavigationBar: manager
                ? SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                      child: FilledButton.icon(
                        key: const Key('create-chat-group'),
                        onPressed: state.mutating
                            ? null
                            : () => _showCreate(context),
                        icon: const Icon(Icons.add_comment_outlined),
                        label: Text(context.tr('Create group')),
                      ),
                    ),
                  )
                : null,
            body: content,
          );
        },
      );

  Widget _body(BuildContext context, ChatGroupsState state) {
    if (state.loading && state.groups.isEmpty) return const AppContentLoading();
    if (state.groups.isEmpty && state.failure != null) {
      return ChatMessageState(
        message: state.failure!.message,
        action: () => context.read<ChatGroupsCubit>().load(),
      );
    }
    final groups = state.groups
        .where((group) => group.isArchived == _archived)
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(context.tr('Active')),
              ),
              ButtonSegment(
                value: true,
                icon: const Icon(Icons.archive_outlined),
                label: Text(context.tr('Archived')),
              ),
            ],
            selected: {_archived},
            onSelectionChanged: (selection) =>
                setState(() => _archived = selection.single),
          ),
        ),
        if (state.failure != null)
          MaterialBanner(
            content: Text(context.tr(state.failure!.message)),
            actions: [
              TextButton(
                onPressed: () =>
                    context.read<ChatGroupsCubit>().load(refresh: true),
                child: Text(context.tr('Retry')),
              ),
            ],
          ),
        Expanded(
          child: groups.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ChatMessageState(
                    message: _archived
                        ? 'No archived chats.'
                        : 'No active chats.',
                  ),
                )
              : RefreshIndicator(
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
                        itemCount: groups.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) => ChatGroupTile(
                          group: groups[index],
                          narrow: narrow,
                          onTap: () =>
                              context
                                      .read<ChatGroupsCubit>()
                                      .scope
                                      ?.isManager ==
                                  true
                              ? context.push(
                                  AppRoutes.chatGroup(groups[index].id),
                                )
                              : Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        ChatScreen(groupId: groups[index].id),
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
      if (!context.mounted) return;
      Fluttertoast.showToast(
        msg: context.tr('Could not load active workspace members.'),
      );
      return;
    }
    if (!context.mounted || cubit.scope != scope) return;
    await ShiftlyChatDialog.showBody<void>(
      context,
      body: CreateChatGroupDialog(
        cubit: cubit,
        scope: scope,
        employees: employees,
      ),
    );
  }
}
