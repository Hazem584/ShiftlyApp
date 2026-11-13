import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:just_audio/just_audio.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/presentation/chat_playback_coordinator.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_location_card.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_remote_image.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_voice_message.dart';
import 'package:shiftly/features/chat/presentation/widgets/message_delivery_status.dart';

import 'chat_document_message.dart';
import 'chat_reaction_picker.dart';
import 'chat_reactions.dart';
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
    this.onReact,
    this.membershipId,
  });
  final ValueChanged<String?>? onReact;
  final String? membershipId;
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
    final foreground = colors.onSurface;
    final bubble = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: mine ? colors.primaryContainer : colors.surface,
        border: null,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: const Radius.circular(16),
          bottomRight: const Radius.circular(16),
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
              message.deletedAt == null
                  ? _content(context)
                  : Text(context.tr('Message deleted')),
              if (message.type == 'IMAGE' &&
                  message.text?.isNotEmpty == true &&
                  message.deletedAt == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(message.text!),
                ),
              if (message.reactions.isNotEmpty && message.deletedAt == null)
                ChatReactions(
                  reactions: message.reactions,
                  membershipId: membershipId,
                  onReact: onReact,
                ),
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
                      DateFormat.Hm(
                        Localizations.localeOf(context).toString(),
                      ).format(
                        WorkspaceTime.inWorkspace(message.createdAt, timezone),
                      ),
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: foreground.withValues(alpha: .72)),
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
            maxWidth: (constraints.maxWidth * .88).clamp(0, 560),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: GestureDetector(
                  onLongPress: () => _actions(context),
                  child: bubble,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _actions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(c.tr('Message actions'))),
            if (onReact != null)
              ListTile(
                leading: const Icon(Icons.add_reaction_outlined),
                title: Text(c.tr('React to message')),
                onTap: () {
                  Navigator.pop(c);
                  _react(context);
                },
              ),
            if (onReply != null)
              ListTile(
                leading: const Icon(Icons.reply),
                title: Text(c.tr('Reply')),
                onTap: () {
                  Navigator.pop(c);
                  onReply!();
                },
              ),
            if (message.text?.isNotEmpty == true)
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text(c.tr('Copy text')),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.text!));
                  Navigator.pop(c);
                },
              ),
            if (onPin != null)
              ListTile(
                leading: const Icon(Icons.push_pin_outlined),
                title: Text(
                  c.tr(
                    message.pinnedAt == null ? 'Pin message' : 'Unpin message',
                  ),
                ),
                onTap: () {
                  Navigator.pop(c);
                  onPin!();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _react(BuildContext context) {
    if (onReact != null) {
      ChatReactionPicker.show(
        context,
        onReact!,
        canRemove: message.reactions.any((r) => r.membershipId == membershipId),
      );
    }
  }

  Widget _content(BuildContext context) => switch (message.type) {
    'TEXT' => Text(message.text ?? ''),
    'DOCUMENT' => ChatDocumentMessage(
      message: message,
      repository: repository,
      workspaceId: workspaceId,
    ),
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
