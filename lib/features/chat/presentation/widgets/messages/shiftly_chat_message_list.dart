import 'package:flutter/material.dart';
import 'package:shiftly/features/chat/data/chat_models.dart';

part 'parts/shiftly_chat_message_list/private_shiftly_chat_message_list_state.dart';
part 'parts/shiftly_chat_message_list/private_chat_date_separator.dart';
part 'parts/shiftly_chat_message_list/private_chat_loading_skeleton.dart';
part 'parts/shiftly_chat_message_list/private_empty_conversation.dart';
part 'parts/shiftly_chat_message_list/private_load_error.dart';

/// Renders the canonical oldest-to-newest conversation from the newest edge.
/// The Cubit owns ordering and de-duplication; this widget owns only scrolling.
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
    super.key,
  });

  final List<ChatMessage> messages;
  final String currentMembershipId;
  final bool loading;
  final String? failureMessage;
  final bool hasMore;
  final bool loadingOlder;
  final Future<void> Function() onLoadOlder;
  final VoidCallback onRetry;
  final Widget Function(ChatMessage message, bool mine, bool showSender)
  messageBuilder;
  final List<Widget> trailingMessages;
  final double bottomPadding;

  @override
  State<ShiftlyChatMessageList> createState() => _ShiftlyChatMessageListState();
}
