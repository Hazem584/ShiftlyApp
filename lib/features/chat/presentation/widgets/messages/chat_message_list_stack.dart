import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import 'chat_message_list_item.dart';
import 'chat_message_list_scroll_mixin.dart';

Widget buildChatMessageListStack(
  BuildContext context,
  ChatMessageListScrollMixin state,
) {
  final widget = state.widget;
  return Stack(
    children: [
      ListView.builder(
        key: const Key('chat-message-list'),
        controller: state.scroll,
        reverse: true,
        padding: EdgeInsets.fromLTRB(12, 12, 12, widget.bottomPadding),
        itemCount: widget.messages.length +
            widget.trailingMessages.length +
            (widget.loadingOlder ? 1 : 0),
        findChildIndexCallback: (key) => findChatMessageChildIndex(widget, key),
        itemBuilder: (_, index) => buildChatMessageListItem(state, index),
      ),
      if (state.showNewMessages)
        Positioned(
          right: 16,
          bottom: 12,
          child: FilledButton.tonalIcon(
            key: const Key('chat-new-messages'),
            onPressed: state.scrollToBottom,
            icon: const Icon(Icons.arrow_downward_rounded, size: 18),
            label: Text(context.tr('New messages')),
          ),
        ),
    ],
  );
}
