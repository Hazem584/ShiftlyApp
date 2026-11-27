import 'package:flutter/material.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_empty_conversation.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_load_error.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_loading_skeleton.dart';

import 'chat_message_list_scroll_mixin.dart';
import 'chat_message_list_stack.dart';

class ShiftlyChatMessageList extends StatefulWidget {
  const ShiftlyChatMessageList({
    required this.messages,
    required this.currentMembershipId,
    required this.loading,
    required this.failureMessage,
    required this.hasMore,
    required this.loadingOlder,
    required this.onLoadOlder,
    required this.onRetry,
    required this.messageBuilder,
    this.trailingMessages = const [],
    this.bottomPadding = 12,
    this.focusMessageId,
    super.key,
  });

  final List<ChatMessage> messages;
  final String currentMembershipId;
  final bool loading, hasMore, loadingOlder;
  final String? failureMessage, focusMessageId;
  final Future<void> Function() onLoadOlder;
  final VoidCallback onRetry;
  final Widget Function(ChatMessage message, bool mine, bool showSender)
      messageBuilder;
  final List<Widget> trailingMessages;
  final double bottomPadding;

  @override
  State<ShiftlyChatMessageList> createState() => _ShiftlyChatMessageListState();
}

class _ShiftlyChatMessageListState extends State<ShiftlyChatMessageList>
    with WidgetsBindingObserver, ChatMessageListScrollMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    scroll.addListener(onScroll);
    if (!widget.loading && widget.messages.isNotEmpty) {
      initialPositioned = true;
      programmaticScroll = true;
      afterLayout(scrollToBottom);
    }
  }

  @override
  void didChangeMetrics() {
    if (nearBottom) afterLayout(scrollToBottom);
  }

  @override
  void didUpdateWidget(covariant ShiftlyChatMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    handleUpdatedMessages(oldWidget);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    scroll.removeListener(onScroll);
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final empty = widget.messages.isEmpty && widget.trailingMessages.isEmpty;
    if (widget.loading && empty) return const ChatLoadingSkeleton();
    if (widget.failureMessage != null && empty) {
      return ChatLoadError(
        message: widget.failureMessage!,
        onRetry: widget.onRetry,
      );
    }
    if (empty) return const ChatEmptyConversation();
    return buildChatMessageListStack(context, this);
  }
}
