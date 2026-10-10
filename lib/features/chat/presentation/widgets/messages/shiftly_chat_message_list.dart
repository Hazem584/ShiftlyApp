import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_date_separator.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_empty_conversation.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_load_error.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_loading_skeleton.dart';

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

class _ShiftlyChatMessageListState extends State<ShiftlyChatMessageList>
    with WidgetsBindingObserver {
  final ScrollController _scroll = ScrollController();
  bool _initialPositioned = false;
  bool _showNewMessages = false;
  bool _programmaticScroll = false;
  bool _anchorLoadInFlight = false;
  final Map<String, GlobalKey> _messageKeys = {};

  bool get _nearBottom => !_scroll.hasClients || _scroll.offset < 120;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_onScroll);
    if (!widget.loading && widget.messages.isNotEmpty) {
      _initialPositioned = true;
      _programmaticScroll = true;
      _afterLayout(_scrollToBottom);
    }
  }

  @override
  void didChangeMetrics() {
    if (!_nearBottom) return;
    _afterLayout(_scrollToBottom);
  }

  @override
  void didUpdateWidget(covariant ShiftlyChatMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final firstLoad =
        !_initialPositioned && !widget.loading && widget.messages.isNotEmpty;
    final appended =
        widget.messages.isNotEmpty &&
        (oldWidget.messages.isEmpty ||
            widget.messages.last.id != oldWidget.messages.last.id);
    final sentByMe =
        appended &&
        widget.messages.last.sender.membershipId == widget.currentMembershipId;
    final pendingAdded =
        widget.trailingMessages.length > oldWidget.trailingMessages.length;
    final canonicalReplacement =
        widget.trailingMessages.length < oldWidget.trailingMessages.length;
    final wasNearBottom = _nearBottom;
    if (firstLoad ||
        (sentByMe && !canonicalReplacement) ||
        pendingAdded ||
        (appended && wasNearBottom)) {
      _initialPositioned = true;
      _programmaticScroll = true;
      _afterLayout(_scrollToBottom);
    } else if (appended) {
      final anchor = _visibleMessage();
      if (anchor != null) {
        _afterLayout(() {
          final box = anchor.key.currentContext?.findRenderObject();
          if (box is RenderBox && box.attached && _scroll.hasClients) {
            final change = anchor.top - box.localToGlobal(Offset.zero).dy;
            _scroll.jumpTo(
              (_scroll.offset + change).clamp(
                _scroll.position.minScrollExtent,
                _scroll.position.maxScrollExtent,
              ),
            );
          }
        });
      }
      setState(() => _showNewMessages = true);
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (!_programmaticScroll &&
        _scroll.position.maxScrollExtent - _scroll.offset <= 80 &&
        widget.hasMore &&
        !widget.loadingOlder &&
        !_anchorLoadInFlight) {
      _loadOlderPreservingAnchor();
    }
    if (_showNewMessages && _nearBottom) {
      setState(() => _showNewMessages = false);
    }
  }

  Future<void> _loadOlderPreservingAnchor() async {
    if (!_scroll.hasClients || _anchorLoadInFlight) return;
    _anchorLoadInFlight = true;
    try {
      // Older messages append at the far edge of a reverse viewport, keeping
      // visible children and their pixels stable without estimated extents.
      await widget.onLoadOlder();
    } finally {
      _anchorLoadInFlight = false;
    }
  }

  ({GlobalKey key, double top})? _visibleMessage() {
    final viewport = context.findRenderObject();
    if (viewport is! RenderBox || !viewport.attached) return null;
    final top = viewport.localToGlobal(Offset.zero).dy;
    for (final message in widget.messages) {
      final key = _messageKeys[message.id];
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

  void _afterLayout(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) callback();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _programmaticScroll = true;
    _scroll
        .animateTo(
          0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() {
          if (mounted) _programmaticScroll = false;
        });
    if (_showNewMessages) setState(() => _showNewMessages = false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading &&
        widget.messages.isEmpty &&
        widget.trailingMessages.isEmpty) {
      return const ChatLoadingSkeleton();
    }
    if (widget.failureMessage != null &&
        widget.messages.isEmpty &&
        widget.trailingMessages.isEmpty) {
      return ChatLoadError(
        message: widget.failureMessage!,
        onRetry: widget.onRetry,
      );
    }
    if (widget.messages.isEmpty && widget.trailingMessages.isEmpty) {
      return const ChatEmptyConversation();
    }
    return Stack(
      children: [
        ListView.builder(
          key: const Key('chat-message-list'),
          controller: _scroll,
          reverse: true,
          padding: EdgeInsets.fromLTRB(12, 12, 12, widget.bottomPadding),
          itemCount:
              widget.messages.length +
              widget.trailingMessages.length +
              (widget.loadingOlder ? 1 : 0),
          findChildIndexCallback: (key) {
            final pending = widget.trailingMessages.indexWhere(
              (widget) => widget.key == key,
            );
            if (pending >= 0) {
              return widget.trailingMessages.length - 1 - pending;
            }
            if (key is! ValueKey<String>) return null;
            const prefix = 'chat-message-';
            if (!key.value.startsWith(prefix)) return null;
            final id = key.value.substring(prefix.length);
            final messageIndex = widget.messages.indexWhere(
              (message) => message.id == id,
            );
            if (messageIndex < 0) return null;
            return widget.trailingMessages.length +
                widget.messages.length -
                1 -
                messageIndex;
          },
          itemBuilder: (context, index) {
            if (index < widget.trailingMessages.length) {
              return widget.trailingMessages[widget.trailingMessages.length -
                  1 -
                  index];
            }
            final messageIndex =
                widget.messages.length -
                1 -
                (index - widget.trailingMessages.length);
            if (messageIndex < 0) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            final message = widget.messages[messageIndex];
            final previous = messageIndex == 0
                ? null
                : widget.messages[messageIndex - 1];
            final showDate =
                previous == null ||
                !DateUtils.isSameDay(
                  previous.createdAt.toLocal(),
                  message.createdAt.toLocal(),
                );
            final showSender =
                previous == null ||
                previous.sender.membershipId != message.sender.membershipId ||
                showDate;
            return KeyedSubtree(
              key: ValueKey('chat-message-${message.id}'),
              child: Column(
                children: [
                  if (showDate) ChatDateSeparator(date: message.createdAt),
                  KeyedSubtree(
                    key: _messageKeys.putIfAbsent(
                      message.id,
                      () => GlobalKey(debugLabel: 'chat-message-${message.id}'),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey('chat-anchor-${message.id}'),
                      child: widget.messageBuilder(
                        message,
                        message.sender.membershipId ==
                            widget.currentMembershipId,
                        showSender,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (_showNewMessages)
          Positioned(
            right: 16,
            bottom: 12,
            child: FilledButton.tonalIcon(
              key: const Key('chat-new-messages'),
              onPressed: _scrollToBottom,
              icon: const Icon(Icons.arrow_downward_rounded, size: 18),
              label: Text(context.tr('New messages')),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }
}
