import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/widgets/app_form_dialog.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_cache_settings_tile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/routing/app_routes.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/data/chat_member_loader.dart';
import 'package:shiftly/features/chat/data/chat_models.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/chat/presentation/dialogs/shiftly_chat_dialog.dart';
import 'package:shiftly/features/chat/presentation/screens/chat_screen.dart';
import 'package:shiftly/features/employees/data/employee_repository.dart';

part 'parts/chat_groups_screen/private_create_chat_group_dialog.dart';
part 'parts/chat_groups_screen/private_create_chat_group_dialog_state.dart';
part 'parts/chat_groups_screen/private_group_tile.dart';
part 'parts/chat_groups_screen/private_message_state.dart';

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
        if (context.read<ChatGroupsCubit>().mediaCache != null)
          const ChatCacheSettingsTile(),
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
    await ShiftlyChatDialog.showBody<void>(
      context,
      body: _CreateChatGroupDialog(
        cubit: cubit,
        scope: scope,
        employees: employees,
      ),
    );
  }
}
