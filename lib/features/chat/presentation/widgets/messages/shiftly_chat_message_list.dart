import 'package:chatview/chatview.dart' as chatview;
import 'package:flutter/material.dart';
import 'package:shiftly/features/chat/data/chat_models.dart';
import 'package:shiftly/features/chat/presentation/adapters/chatview_message_adapter.dart';

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
  final Widget Function(ChatMessage message, bool mine) messageBuilder;

  @override
  State<ShiftlyChatMessageList> createState() => _ShiftlyChatMessageListState();
}

class _ShiftlyChatMessageListState extends State<ShiftlyChatMessageList> {
  late final chatview.ChatController _controller;

  @override
  void initState() {
    super.initState();
    _controller = chatview.ChatController(
      initialMessageList: _mappedMessages(),
      scrollController: ScrollController(),
      otherUsers: _otherUsers(),
      currentUser: chatview.ChatUser(
        id: widget.currentMembershipId,
        name: 'You',
      ),
    );
  }

  @override
  void didUpdateWidget(covariant ShiftlyChatMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final user in _otherUsers()) {
      _controller.updateOtherUser(user);
    }
    final mapped = _mappedMessages();
    final changed =
        mapped.length != _controller.initialMessageList.length ||
        mapped.indexed.any(
          (entry) => _controller.initialMessageList[entry.$1].id != entry.$2.id,
        );
    if (changed && !_controller.messageStreamController.isClosed) {
      _controller.initialMessageList = mapped;
      _controller.messageStreamController.add(mapped);
    }
  }

  List<chatview.Message> _mappedMessages() => widget.messages
      .map((message) => ChatViewMessageAdapter.fromShiftly(message).message)
      .toList(growable: false);

  List<chatview.ChatUser> _otherUsers() {
    final senders = <String, ChatSender>{};
    for (final message in widget.messages) {
      if (message.sender.membershipId != widget.currentMembershipId) {
        senders[message.sender.membershipId] = message.sender;
      }
    }
    return senders.values
        .map(ChatViewMessageAdapter.user)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final byId = {for (final message in widget.messages) message.id: message};
    final colors = Theme.of(context).colorScheme;
    return chatview.ChatView(
      chatController: _controller,
      chatViewState: widget.loading
          ? chatview.ChatViewState.loading
          : widget.failureMessage != null && widget.messages.isEmpty
          ? chatview.ChatViewState.error
          : widget.messages.isEmpty
          ? chatview.ChatViewState.noData
          : chatview.ChatViewState.hasMessages,
      chatViewStateConfig: chatview.ChatViewStateConfiguration(
        loadingWidgetConfig: chatview.ChatViewStateWidgetConfiguration(
          widget: const _ChatLoadingSkeleton(),
        ),
        noMessageWidgetConfig: const chatview.ChatViewStateWidgetConfiguration(
          widget: _EmptyConversation(),
        ),
        errorWidgetConfig: chatview.ChatViewStateWidgetConfiguration(
          widget: _LoadError(
            message: widget.failureMessage ?? 'Unable to load messages.',
            onRetry: widget.onRetry,
          ),
        ),
      ),
      loadMoreData: (_, _) => widget.onLoadOlder(),
      isLastPage: () => !widget.hasMore,
      loadingWidget: widget.loadingOlder
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      featureActiveConfig: const chatview.FeatureActiveConfig(
        enableTextField: false,
        enablePagination: true,
        enableSwipeToReply: false,
        enableReactionPopup: false,
        enableDoubleTapToLike: false,
        enableReplySnackBar: false,
        enableSwipeToSeeTime: false,
        enableOtherUserProfileAvatar: false,
        enableOtherUserName: false,
        enableCurrentUserProfileAvatar: false,
        receiptsBuilderVisibility: false,
        lastSeenAgoBuilderVisibility: false,
        enableScrollToBottomButton: true,
      ),
      messageConfig: chatview.MessageConfiguration(
        showReactionsOnCustomMessages: false,
        customMessageBuilder: (packageMessage) {
          final message = byId[packageMessage.id];
          if (message == null) return const SizedBox.shrink();
          return widget.messageBuilder(
            message,
            message.sender.membershipId == widget.currentMembershipId,
          );
        },
      ),
      chatBackgroundConfig: chatview.ChatBackgroundConfiguration(
        backgroundColor: colors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        groupedListOrder: chatview.GroupedListOrder.asc,
        sortEnable: true,
        messageSorter: (a, b) => a.createdAt.compareTo(b.createdAt),
        groupSeparatorBuilder: _daySeparator,
      ),
    );
  }

  Widget _daySeparator(String value) {
    final parsed = DateTime.tryParse(value);
    final now = DateTime.now();
    final date = parsed?.toLocal();
    final text = date == null
        ? value
        : DateUtils.isSameDay(date, now)
        ? 'Today'
        : DateUtils.isSameDay(date, now.subtract(const Duration(days: 1)))
        ? 'Yesterday'
        : MaterialLocalizations.of(context).formatMediumDate(date);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(text, style: Theme.of(context).textTheme.labelSmall),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _ChatLoadingSkeleton extends StatelessWidget {
  const _ChatLoadingSkeleton();

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: 6,
    itemBuilder: (_, index) => Align(
      alignment: index.isEven ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        width: index.isEven ? 210 : 160,
        height: 52,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    ),
  );
}

class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.forum_outlined, size: 44),
        SizedBox(height: 12),
        Text('No messages yet. Start the conversation.'),
      ],
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, textAlign: TextAlign.center),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
