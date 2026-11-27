import 'package:flutter/material.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_date_separator.dart';

import 'chat_message_list_scroll_mixin.dart';
import 'shiftly_chat_message_list.dart';

int? findChatMessageChildIndex(ShiftlyChatMessageList widget, Key key) {
  final pending = widget.trailingMessages.indexWhere((w) => w.key == key);
  if (pending >= 0) return widget.trailingMessages.length - 1 - pending;
  if (key is! ValueKey<String>) return null;
  const prefix = 'chat-message-';
  if (!key.value.startsWith(prefix)) return null;
  final id = key.value.substring(prefix.length);
  final messageIndex = widget.messages.indexWhere((m) => m.id == id);
  if (messageIndex < 0) return null;
  return widget.trailingMessages.length +
      widget.messages.length -
      1 -
      messageIndex;
}

Widget buildChatMessageListItem(
  ChatMessageListScrollMixin state,
  int index,
) {
  final widget = state.widget;
  if (index < widget.trailingMessages.length) {
    return widget.trailingMessages[widget.trailingMessages.length - 1 - index];
  }
  final messageIndex =
      widget.messages.length - 1 - (index - widget.trailingMessages.length);
  if (messageIndex < 0) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
  final message = widget.messages[messageIndex];
  final previous = messageIndex == 0 ? null : widget.messages[messageIndex - 1];
  final showDate = previous == null ||
      !DateUtils.isSameDay(
        previous.createdAt.toLocal(),
        message.createdAt.toLocal(),
      );
  final showSender = previous == null ||
      previous.sender.membershipId != message.sender.membershipId ||
      showDate;
  return KeyedSubtree(
    key: ValueKey('chat-message-${message.id}'),
    child: Column(
      children: [
        if (showDate) ChatDateSeparator(date: message.createdAt),
        KeyedSubtree(
          key: state.messageKeys.putIfAbsent(
            message.id,
            () => GlobalKey(debugLabel: 'chat-message-${message.id}'),
          ),
          child: KeyedSubtree(
            key: ValueKey('chat-anchor-${message.id}'),
            child: widget.messageBuilder(
              message,
              message.sender.membershipId == widget.currentMembershipId,
              showSender,
            ),
          ),
        ),
      ],
    ),
  );
}
