import 'package:flutter/material.dart';

import 'chat_message_list_scroll_mixin.dart';

Future<void> focusChatMessageInList(
  ChatMessageListScrollMixin state,
  String id,
) async {
  final scroll = state.scroll;
  state.programmaticScroll = true;
  try {
    for (var step = 0;
        step <= state.widget.messages.length && state.mounted;
        step++) {
      if (state.widget.focusMessageId != id || !scroll.hasClients) return;
      final target = state.messageKeys[id]?.currentContext;
      if (target != null && target.mounted) {
        await Scrollable.ensureVisible(
          target,
          alignment: .45,
          duration: const Duration(milliseconds: 180),
        );
        return;
      }
      final targetIndex = state.widget.messages.indexWhere((m) => m.id == id);
      if (targetIndex < 0) return;
      final visible = state.widget.messages.indexWhere(
        (m) => state.messageKeys[m.id]?.currentContext != null,
      );
      final dir = visible < 0 || targetIndex < visible ? 1 : -1;
      final next =
          (scroll.offset + dir * scroll.position.viewportDimension * .75)
              .clamp(0.0, scroll.position.maxScrollExtent);
      if (next == scroll.offset) return;
      scroll.jumpTo(next);
      await WidgetsBinding.instance.endOfFrame;
    }
  } finally {
    if (state.mounted) state.programmaticScroll = false;
  }
}

({GlobalKey key, double top})? findVisibleChatMessage(
  ChatMessageListScrollMixin state,
) {
  final viewport = state.context.findRenderObject();
  if (viewport is! RenderBox || !viewport.attached) return null;
  final top = viewport.localToGlobal(Offset.zero).dy;
  for (final message in state.widget.messages) {
    final key = state.messageKeys[message.id];
    final box = key?.currentContext?.findRenderObject();
    if (key != null && box is RenderBox && box.attached) {
      final y = box.localToGlobal(Offset.zero).dy;
      if (y + box.size.height > top && y < top + viewport.size.height) {
        return (key: key, top: y);
      }
    }
  }
  return null;
}
