part of '../../shiftly_chat_message_list.dart';

class _ShiftlyChatMessageListState extends State<ShiftlyChatMessageList>
    with WidgetsBindingObserver {
  final ScrollController _scroll = ScrollController();
  bool _initialPositioned = false;
  bool _showNewMessages = false;
  bool _programmaticScroll = false;
  bool _anchorLoadInFlight = false;
  final Map<String, GlobalKey> _messageKeys = {};

  bool get _nearBottom =>
      !_scroll.hasClients ||
      _scroll.position.maxScrollExtent - _scroll.offset < 120;

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
    final wasNearBottom = _nearBottom;
    if (firstLoad || sentByMe || pendingAdded || (appended && wasNearBottom)) {
      _initialPositioned = true;
      _programmaticScroll = true;
      _afterLayout(_scrollToBottom);
    } else if (appended) {
      setState(() => _showNewMessages = true);
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (!_programmaticScroll &&
        _scroll.offset <= 80 &&
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
    final beforeExtent = _scroll.position.maxScrollExtent;
    final beforeOffset = _scroll.offset;
    final anchor = _visibleAnchor();
    try {
      await widget.onLoadOlder();
      if (!mounted) return;
      void restoreAnchor(int attemptsRemaining) {
        if (!_scroll.hasClients) return;
        debugPrint('RESTORE $attemptsRemaining ${_scroll.offset}');
        final anchorContext = anchor?.key.currentContext;
        final anchorBox = anchorContext?.findRenderObject();
        if (anchorBox is RenderBox &&
            anchorBox.attached &&
            _intersectsViewport(anchorBox) &&
            _messageId(anchorContext!) == anchor!.id) {
          final currentTop = anchorBox.localToGlobal(Offset.zero).dy;
          _scroll.jumpTo(_scroll.offset + currentTop - anchor!.top);
          return;
        }
        if (attemptsRemaining == 8) {
          final added = _scroll.position.maxScrollExtent - beforeExtent;
          _scroll.jumpTo(
            (beforeOffset + added).clamp(
              _scroll.position.minScrollExtent,
              _scroll.position.maxScrollExtent,
            ),
          );
        } else if (anchor != null) {
          final anchorIndex = widget.messages.indexWhere(
            (message) => message.id == anchor.id,
          );
          final visibleIndices = <int>[];
          for (final key in _messageKeys.values) {
            final messageContext = key.currentContext;
            final renderObject = messageContext?.findRenderObject();
            if (messageContext == null ||
                renderObject is! RenderBox ||
                !renderObject.attached ||
                !_intersectsViewport(renderObject)) {
              continue;
            }
            final id = _messageId(messageContext);
            final index = widget.messages.indexWhere(
              (message) => message.id == id,
            );
            if (index >= 0) visibleIndices.add(index);
          }
          visibleIndices.sort();
          if (anchorIndex >= 0 && visibleIndices.isNotEmpty) {
            final direction = visibleIndices.first > anchorIndex ? -1 : 1;
            final target =
                _scroll.offset +
                direction * _scroll.position.viewportDimension * .75;
            _scroll.jumpTo(
              target.clamp(
                _scroll.position.minScrollExtent,
                _scroll.position.maxScrollExtent,
              ),
            );
          }
        }
        if (attemptsRemaining > 0) {
          _afterLayout(() => restoreAnchor(attemptsRemaining - 1));
        }
      }

      _afterLayout(() => restoreAnchor(8));
    } finally {
      _anchorLoadInFlight = false;
    }
  }

  ({String id, GlobalKey key, double top})? _visibleAnchor() {
    final viewport = context.findRenderObject();
    if (viewport is! RenderBox || !viewport.attached) return null;
    final viewportTop = viewport.localToGlobal(Offset.zero).dy;
    final viewportBottom = viewportTop + viewport.size.height;
    for (final message in widget.messages) {
      final key = _messageKeys[message.id];
      final renderObject = key?.currentContext?.findRenderObject();
      if (key == null || renderObject is! RenderBox || !renderObject.attached) {
        continue;
      }
      final top = renderObject.localToGlobal(Offset.zero).dy;
      final bottom = top + renderObject.size.height;
      if (bottom > viewportTop && top < viewportBottom) {
        return (id: message.id, key: key, top: top);
      }
    }
    return null;
  }

  String? _messageId(BuildContext context) {
    final widget = context.widget;
    if (widget is! KeyedSubtree || widget.child is! KeyedSubtree) return null;
    final key = (widget.child as KeyedSubtree).key;
    if (key is! ValueKey<String>) return null;
    const prefix = 'chat-message-';
    return key.value.startsWith(prefix)
        ? key.value.substring(prefix.length)
        : null;
  }

  bool _intersectsViewport(RenderBox box) {
    final viewport = context.findRenderObject();
    if (viewport is! RenderBox || !viewport.attached) return false;
    final viewportTop = viewport.localToGlobal(Offset.zero).dy;
    final viewportBottom = viewportTop + viewport.size.height;
    final top = box.localToGlobal(Offset.zero).dy;
    return top + box.size.height > viewportTop && top < viewportBottom;
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
          _scroll.position.maxScrollExtent,
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
    if (widget.loading && widget.messages.isEmpty) {
      return const _ChatLoadingSkeleton();
    }
    if (widget.failureMessage != null && widget.messages.isEmpty) {
      return _LoadError(
        message: widget.failureMessage!,
        onRetry: widget.onRetry,
      );
    }
    if (widget.messages.isEmpty) return const _EmptyConversation();
    return Stack(
      children: [
        ListView.builder(
          key: const Key('chat-message-list'),
          controller: _scroll,
          padding: EdgeInsets.fromLTRB(12, 12, 12, widget.bottomPadding),
          itemCount:
              widget.messages.length +
              widget.trailingMessages.length +
              (widget.loadingOlder ? 1 : 0),
          itemBuilder: (context, index) {
            if (widget.loadingOlder && index == 0) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            final messageIndex = index - (widget.loadingOlder ? 1 : 0);
            if (messageIndex >= widget.messages.length) {
              return widget.trailingMessages[messageIndex -
                  widget.messages.length];
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
              key: _messageKeys.putIfAbsent(
                message.id,
                () => GlobalKey(debugLabel: 'chat-message-${message.id}'),
              ),
              child: KeyedSubtree(
                key: ValueKey('chat-message-${message.id}'),
                child: Column(
                  children: [
                    if (showDate) _ChatDateSeparator(date: message.createdAt),
                    widget.messageBuilder(
                      message,
                      message.sender.membershipId ==
                          widget.currentMembershipId,
                      showSender,
                    ),
                  ],
                ),
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
              label: const Text('New messages'),
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
