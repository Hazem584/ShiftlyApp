import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/presentation/chat_playback_coordinator.dart';

import 'chat_message_actions_sheet.dart';
import 'chat_message_bubble_body.dart';
import 'chat_message_media_content.dart';
import 'chat_reaction_picker.dart';

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
    final bubble = ChatMessageBubbleBody(
      message: message,
      mine: mine,
      showSender: showSender,
      timezone: timezone,
      readByAll: readByAll,
      membershipId: membershipId,
      onReact: onReact,
      content: message.deletedAt == null
          ? buildChatMessageContent(
              context,
              message: message,
              repository: repository,
              workspaceId: workspaceId,
              player: player,
              playback: playback,
            )
          : const SizedBox.shrink(),
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
                  onLongPress: () => showChatMessageActions(
                    context,
                    message: message,
                    onReply: onReply,
                    onPin: onPin,
                    onReact: onReact == null ? null : () => _react(context),
                  ),
                  child: bubble,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _react(BuildContext context) => ChatReactionPicker.show(
    context,
    onReact!,
    canRemove: message.reactions.any((r) => r.membershipId == membershipId),
  );
}
