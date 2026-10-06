part of '../../chat_screen.dart';

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.mine,
    required this.showSender,
    required this.repository,
    required this.workspaceId,
    required this.timezone,
    required this.player,
  });
  final ChatMessage message;
  final bool mine;
  final bool showSender;
  final ChatRepository repository;
  final String workspaceId;
  final String timezone;
  final AudioPlayer player;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = mine
        ? colors.onPrimaryContainer
        : colors.onSurfaceVariant;
    final bubble = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: mine ? colors.primaryContainer : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(mine ? 18 : 5),
          bottomRight: Radius.circular(mine ? 5 : 18),
        ),
      ),
      child: IconTheme(
        data: IconThemeData(color: foreground),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: foreground),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!mine && showSender)
                Text(
                  message.sender.displayName,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: foreground),
                ),
              _content(context),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  WorkspaceTime.time(message.createdAt, timezone),
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: foreground.withValues(alpha: .72)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth * .76),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!mine && showSender) ...[
                CircleAvatar(
                  radius: 15,
                  backgroundImage: message.sender.avatarUrl == null
                      ? null
                      : NetworkImage(message.sender.avatarUrl!),
                  child: message.sender.avatarUrl == null
                      ? Text(
                          _nameInitials(message.sender.displayName),
                          style: Theme.of(context).textTheme.labelSmall,
                        )
                      : null,
                ),
                const SizedBox(width: 7),
              ],
              Flexible(child: bubble),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) => switch (message.type) {
    'TEXT' => SelectableText(message.text ?? ''),
    'IMAGE' => _RemoteImage(
      repository: repository,
      workspaceId: workspaceId,
      message: message,
    ),
    'VOICE' => _VoiceMessage(
      repository: repository,
      workspaceId: workspaceId,
      message: message,
      player: player,
    ),
    'LOCATION' => _LocationCard(location: message.location),
    _ => const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.help_outline, size: 18),
        SizedBox(width: 8),
        Text('Unsupported message'),
      ],
    ),
  };
}
