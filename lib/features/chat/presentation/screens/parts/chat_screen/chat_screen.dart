part of '../../chat_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({required this.groupId, super.key});
  final String groupId;

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<ChatGroupsCubit>();
    final scope = groups.scope;
    if (scope == null) {
      return const Scaffold(
        body: Center(child: Text('Chat session is no longer active.')),
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
      child: _ChatView(groupId: groupId),
    );
  }
}
