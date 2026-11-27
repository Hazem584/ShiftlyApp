import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

import 'chat_message_delivery_footer.dart';
import 'chat_message_pinned_label.dart';
import 'chat_reactions.dart';
import 'chat_reply_preview.dart';

class ChatMessageBubbleBody extends StatelessWidget {
  const ChatMessageBubbleBody({
    required this.message,
    required this.mine,
    required this.showSender,
    required this.timezone,
    required this.readByAll,
    required this.content,
    required this.membershipId,
    required this.onReact,
    super.key,
  });
  final ChatMessage message;
  final bool mine, showSender, readByAll;
  final String timezone;
  final Widget content;
  final String? membershipId;
  final ValueChanged<String?>? onReact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = colors.onSurface;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: mine ? colors.primaryContainer : colors.surface,
        borderRadius: BorderRadius.circular(16),
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
                  ? content
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
              if (message.pinnedAt != null) const ChatMessagePinnedLabel(),
              ChatMessageDeliveryFooter(
                createdAt: message.createdAt,
                timezone: timezone,
                mine: mine,
                readByAll: readByAll,
                foreground: foreground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
