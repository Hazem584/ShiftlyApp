import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/presentation/chat_playback_coordinator.dart';
import 'package:shiftly/features/chat/presentation/utils/chat_formatters.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_location_card.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_remote_image.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_voice_message.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.mine,
    required this.showSender,
    required this.repository,
    required this.workspaceId,
    required this.timezone,
    required this.player,
    this.playback,
  });
  final ChatMessage message;
  final bool mine;
  final bool showSender;
  final ChatRepository repository;
  final String workspaceId;
  final String timezone;
  final AudioPlayer player;
  final ChatPlaybackCoordinator? playback;
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
                  WorkspaceTime.time(
                    message.createdAt,
                    timezone,
                    locale: Localizations.localeOf(context).toString(),
                  ),
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
                          chatScreenNameInitials(message.sender.displayName),
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
    'IMAGE' => ChatRemoteImage(
      repository: repository,
      workspaceId: workspaceId,
      message: message,
    ),
    'VOICE' => ChatVoiceMessage(
      repository: repository,
      workspaceId: workspaceId,
      message: message,
      player: player,
      playback: playback,
    ),
    'LOCATION' => ChatLocationCard(location: message.location),
    _ => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.help_outline, size: 18),
        const SizedBox(width: 8),
        Text(context.tr('Unsupported message')),
      ],
    ),
  };
}
