import 'package:flutter/material.dart';

import 'chat_message_list_anchor.dart';
import 'chat_message_list_scroll_mixin.dart';
import 'shiftly_chat_message_list.dart';

void restoreChatMessageListAnchor(
  ChatMessageListScrollMixin state,
  ({GlobalKey key, double top})? anchor,
) {
  if (anchor == null) return;
  state.afterLayout(() {
    final box = anchor.key.currentContext?.findRenderObject();
    if (box is RenderBox && box.attached && state.scroll.hasClients) {
      final change = anchor.top - box.localToGlobal(Offset.zero).dy;
      state.scroll.jumpTo(
        (state.scroll.offset + change).clamp(
          state.scroll.position.minScrollExtent,
          state.scroll.position.maxScrollExtent,
        ),
      );
    }
  });
}

void handleUpdatedChatMessageList(
  ChatMessageListScrollMixin state,
  ShiftlyChatMessageList oldWidget,
) {
  final widget = state.widget;
  if (widget.focusMessageId != null &&
      widget.focusMessageId != oldWidget.focusMessageId) {
    state.afterLayout(
      () => focusChatMessageInList(state, widget.focusMessageId!),
    );
    return;
  }
  final firstLoad =
      !state.initialPositioned && !widget.loading && widget.messages.isNotEmpty;
  final appended = widget.messages.isNotEmpty &&
      (oldWidget.messages.isEmpty ||
          widget.messages.last.id != oldWidget.messages.last.id);
  final sentByMe = appended &&
      widget.messages.last.sender.membershipId == widget.currentMembershipId;
  final pendingAdded =
      widget.trailingMessages.length > oldWidget.trailingMessages.length;
  final canonicalRep =
      widget.trailingMessages.length < oldWidget.trailingMessages.length;
  if (firstLoad ||
      (sentByMe && !canonicalRep) ||
      pendingAdded ||
      (appended && state.nearBottom)) {
    state.initialPositioned = true;
    state.programmaticScroll = true;
    state.afterLayout(state.scrollToBottom);
  } else if (appended) {
    restoreChatMessageListAnchor(state, findVisibleChatMessage(state));
    state.showNewMessagesBanner();
  }
}
