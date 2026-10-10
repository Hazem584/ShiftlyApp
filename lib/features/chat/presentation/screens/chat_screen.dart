import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
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
    return MultiBlocProvider(
      key: ValueKey(
        '${scope.userId}:${scope.workspaceId}:${scope.generation}:$groupId',
      ),
      providers: [
        BlocProvider(
          create: (_) => ChatGroupDetailsCubit(
            repository,
            onChanged: () => groups.load(refresh: true),
            cacheDatabase: groups.messageCache?.storage,
          )..bind(scope, groupId),
        ),
        BlocProvider(
          create: (_) => ChatConversationCubit(
            repository,
            context.read<ChatRealtime>(),
            messageCache: groups.messageCache,
            outbox: groups.outbox,
            onChanged: () => groups.load(refresh: true),
          )..bind(scope, groupId),
        ),
      ],
      child: ChatConversationView(groupId: groupId),
    );
  }
}
