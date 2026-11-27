import 'package:flutter/material.dart';

import 'chat_message_list_updater.dart';
import 'shiftly_chat_message_list.dart';

mixin ChatMessageListScrollMixin on State<ShiftlyChatMessageList> {
  final ScrollController scroll = ScrollController();
  bool initialPositioned = false;
  bool showNewMessages = false;
  bool programmaticScroll = false;
  bool anchorLoadInFlight = false;
  final Map<String, GlobalKey> messageKeys = {};

  bool get nearBottom => !scroll.hasClients || scroll.offset < 120;
  void showNewMessagesBanner() => setState(() => showNewMessages = true);

  void onScroll() {
    if (!scroll.hasClients) return;
    if (!programmaticScroll &&
        scroll.position.maxScrollExtent - scroll.offset <= 80 &&
        widget.hasMore &&
        !widget.loadingOlder &&
        !anchorLoadInFlight) {
      loadOlderPreservingAnchor();
    }
    if (showNewMessages && nearBottom) {
      setState(() => showNewMessages = false);
    }
  }

  Future<void> loadOlderPreservingAnchor() async {
    if (!scroll.hasClients || anchorLoadInFlight) return;
    anchorLoadInFlight = true;
    try {
      await widget.onLoadOlder();
    } finally {
      anchorLoadInFlight = false;
    }
  }

  void afterLayout(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) callback();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void scrollToBottom() {
    if (!scroll.hasClients) return;
    programmaticScroll = true;
    scroll
        .animateTo(
          0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() {
          if (mounted) programmaticScroll = false;
        });
    if (showNewMessages) setState(() => showNewMessages = false);
  }

  void handleUpdatedMessages(ShiftlyChatMessageList oldWidget) =>
      handleUpdatedChatMessageList(this, oldWidget);
}
