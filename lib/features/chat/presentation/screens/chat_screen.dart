import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/collaboration_appearance.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_realtime.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_group_details_cubit.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_conversation_view.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({required this.groupId, super.key});
  final String groupId;

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<ChatGroupsCubit>();
    final scope = groups.scope;
    if (scope == null) {
      return Scaffold(
        body: Center(
          child: Text(context.tr('Chat session is no longer active.')),
        ),
      );
    }
    final repository = context.read<ChatRepository>();
    Future<ChatGroup>? groupRequest;
    // Details and history share only an in-flight authorization request.
    // No authorization result is retained across sessions or later refreshes.
    Future<ChatGroup> loadGroup() => groupRequest ??= repository
        .getGroup(scope.workspaceId, groupId)
        .whenComplete(() => groupRequest = null);
    return MultiBlocProvider(
      key: ValueKey(
        '${scope.userId}:${scope.workspaceId}:${scope.generation}:$groupId',
      ),
      providers: [
        BlocProvider(
          create: (_) =>
              ChatGroupDetailsCubit(
                repository,
                realtime: context.read<ChatRealtime>(),
                loadGroup: loadGroup,
                onChanged: () => groups.load(refresh: true),
                cacheDatabase: groups.messageCache?.storage,
              )..bind(
                scope,
                groupId,
                initialGroup: groups.state.groups
                    .where((group) => group.id == groupId)
                    .firstOrNull,
              ),
        ),
        BlocProvider(
          create: (_) =>
              ChatConversationCubit(
                  repository,
                  context.read<ChatRealtime>(),
                  loadGroup: loadGroup,
                  messageCache: groups.messageCache,
                  outbox: groups.outbox,
                  onChanged: () => groups.load(refresh: true),
                )
                ..bind(scope, groupId)
                ..syncInboxGroup(
                  groups.state.groups.where((g) => g.id == groupId).firstOrNull,
                ),
        ),
      ],
      child: Builder(
        builder: (context) => MultiBlocListener(
          listeners: [
            BlocListener<ChatGroupsCubit, ChatGroupsState>(
              listener: (context, state) =>
                  context.read<ChatConversationCubit>().syncInboxGroup(
                    state.groups.where((g) => g.id == groupId).firstOrNull,
                  ),
            ),
            // Access checks also return the last message. They repair a missed
            // channel event after foreground/resume without requiring a send.
            BlocListener<ChatGroupDetailsCubit, ChatGroupDetailsState>(
              listener: (context, state) => context
                  .read<ChatConversationCubit>()
                  .syncInboxGroup(state.group),
            ),
          ],
          child: CollaborationAppearance(
            child: ChatConversationView(groupId: groupId),
          ),
        ),
      ),
    );
  }
}
