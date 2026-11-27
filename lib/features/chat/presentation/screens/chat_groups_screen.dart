import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/collaboration_appearance.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';

import '../controllers/show_create_chat_group.dart';
import 'chat_groups_body.dart';

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
          final content = ChatGroupsBody(
            state: state,
            archived: _archived,
            onArchiveSelected: (value) => setState(() => _archived = value),
          );

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
                            : () => showCreateChatGroup(context),
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
}
