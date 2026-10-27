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
import 'package:shiftly/features/chat/presentation/widgets/message_delivery_status.dart';

import 'chat_reply_preview.dart';

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
    this.readByAll = false,
    this.onReply,
    this.onPin,
  });
  final ChatMessage message;
  final bool mine;
  final bool showSender;
  final ChatRepository repository;
  final String workspaceId;
  final String timezone;
  final AudioPlayer player;
  final ChatPlaybackCoordinator? playback;
  final bool readByAll;
  final VoidCallback? onReply, onPin;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = mine ? colors.onPrimary : colors.onSurface;
    final bubble = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: mine ? colors.primary : colors.surface,
        border: mine ? null : Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
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
              if (message.replyToMessageId != null)
                ChatReplyPreview(
                  name:
                      message.replyPreview?['senderName'] as String? ??
                      context.tr('Reply'),
                  text:
                      message.replyPreview?['text'] as String? ??
                      context.tr('Message'),
                ),
              _content(context),
              if (message.pinnedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.push_pin, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        context.tr('Pinned'),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      WorkspaceTime.time(
                        message.createdAt,
                        timezone,
                        locale: Localizations.localeOf(context).toString(),
                      ),
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: foreground.withValues(alpha: .72)),
                    ),
                    if (onReply != null || onPin != null)
                      PopupMenuButton<String>(
                        tooltip: context.tr('Message actions'),
                        onSelected: (action) =>
                            action == 'reply' ? onReply?.call() : onPin?.call(),
                        itemBuilder: (_) => [
                          if (onReply != null)
                            PopupMenuItem(
                              value: 'reply',
                              child: Text(context.tr('Reply')),
                            ),
                          if (onPin != null)
                            PopupMenuItem(
                              value: 'pin',
                              child: Text(
                                context.tr(
                                  message.pinnedAt == null
                                      ? 'Pin message'
                                      : 'Unpin message',
                                ),
                              ),
                            ),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Icon(
                            Icons.more_horiz,
                            size: 18,
                            color: foreground,
                          ),
                        ),
                      ),
                    if (mine) ...[
                      const SizedBox(width: 5),
                      MessageDeliveryStatus(readByAll: readByAll),
                    ],
                  ],
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
          constraints: BoxConstraints(
            maxWidth: (constraints.maxWidth * .82).clamp(0, 560),
          ),
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
