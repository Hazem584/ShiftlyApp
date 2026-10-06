part of '../../chat_screen.dart';

class _ChatViewState extends State<_ChatView> with WidgetsBindingObserver {
  final _text = TextEditingController();
  final _picker = ImagePicker();
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  StreamSubscription<RecordState>? _recordState;
  Timer? _recordTimer;
  DateTime? _recordStarted;
  bool _recording = false;
  bool _mediaBusy = false;
  String? _recordPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _recordState = _recorder.onStateChanged().listen((value) {
      if ((value == RecordState.stop || value == RecordState.pause) &&
          _recording) {
        unawaited(_handleRecordingInterruption());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_player.pause());
      if (_recording) unawaited(_handleRecordingInterruption());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordTimer?.cancel();
    unawaited(_recordState?.cancel());
    unawaited(_recorder.cancel());
    _recorder.dispose();
    _player.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<ChatGroupDetailsCubit, ChatGroupDetailsState>(
    builder: (context, details) {
      final group = details.group;
      final manager = context.read<ChatGroupsCubit>().scope?.isManager == true;
      return Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  _initials(group?.name ?? 'Chat'),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group?.name ?? 'Chat',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (group != null)
                      Text(
                        group.isArchived
                            ? '${group.memberCount} members · Read only'
                            : '${group.memberCount} members',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Group members',
              onPressed: group == null ? null : () => _showMembers(group),
              icon: const Icon(Icons.group_outlined),
            ),
            if (manager && group != null && !group.isArchived)
              PopupMenuButton<String>(
                onSelected: (value) =>
                    value == 'edit' ? _edit(group) : _archive(group),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit group')),
                  PopupMenuItem(value: 'archive', child: Text('Archive group')),
                ],
              ),
          ],
        ),
        body: Column(
          children: [
            if (details.failure != null)
              MaterialBanner(
                content: Text(details.failure!.message),
                actions: [
                  TextButton(
                    onPressed: context.read<ChatGroupDetailsCubit>().load,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            if (group?.isArchived == true)
              ColoredBox(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Icon(Icons.archive_outlined, size: 18),
                      Text('Archived group — read only'),
                    ],
                  ),
                ),
              ),
            Expanded(child: _messages()),
            _composer(disabled: group == null || group.isArchived),
          ],
        ),
      );
    },
  );

  String _initials(String value) {
    final words = value.trim().split(RegExp(r'\s+'));
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }

  Widget _messages() =>
      BlocBuilder<ChatConversationCubit, ChatConversationState>(
        builder: (context, state) {
          final scope = context.read<ChatGroupsCubit>().scope!;
          return RefreshIndicator(
            onRefresh: () =>
                context.read<ChatConversationCubit>().load(refresh: true),
            child: ShiftlyChatMessageList(
              key: ValueKey(
                '${scope.userId}:${scope.workspaceId}:${widget.groupId}',
              ),
              messages: state.messages,
              currentMembershipId: scope.membershipId,
              loading: state.loading,
              failureMessage: state.messages.isEmpty
                  ? state.failure?.message
                  : null,
              hasMore: state.hasMore,
              loadingOlder: state.loadingOlder,
              onLoadOlder: context.read<ChatConversationCubit>().loadOlder,
              onRetry: context.read<ChatConversationCubit>().load,
              trailingMessages: [
                if (state.sending && _text.text.trim().isNotEmpty)
                  _PendingTextBubble(text: _text.text.trim()),
                for (final pending in state.pending)
                  PendingMediaBubble(
                    key: ValueKey(pending.clientMessageId),
                    pending: pending,
                    onRetry: (id) =>
                        context.read<ChatConversationCubit>().retryMedia(id),
                    onCancel: _confirmCancelPending,
                  ),
              ],
              messageBuilder: (message, mine, showSender) => _MessageBubble(
                message: message,
                mine: mine,
                showSender: showSender,
                repository: context.read<ChatRepository>(),
                workspaceId: scope.workspaceId,
                timezone: scope.timezone,
                player: _player,
              ),
            ),
          );
        },
      );

  Future<void> _confirmCancelPending(String clientId) async {
    final confirmed = await ShiftlyChatDialog.confirm(
      context,
      title: 'Cancel upload?',
      message: 'The pending media will be removed from this conversation.',
      confirmText: 'Cancel upload',
      destructive: true,
    );
    if (confirmed && mounted) {
      await context.read<ChatConversationCubit>().cancelPending(clientId);
    }
  }

  Widget _composer({required bool disabled}) => SafeArea(
    top: false,
    child: BlocBuilder<ChatConversationCubit, ChatConversationState>(
      builder: (context, state) {
        final effectiveDisabled = disabled || state.accessLost;
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.failedText != null)
                Row(
                  children: [
                    const Expanded(child: Text('Message failed to send.')),
                    TextButton(
                      onPressed: state.sending
                          ? null
                          : context.read<ChatConversationCubit>().retrySend,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    PopupMenuButton<int>(
                      tooltip: 'Attach',
                      enabled:
                          !effectiveDisabled && !state.sending && !_mediaBusy,
                      onSelected: (value) {
                        if (value == 0) unawaited(_pickImage());
                        if (value == 1) unawaited(_startRecording());
                        if (value == 2) unawaited(_shareLocation());
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 0, child: Text('Image')),
                        PopupMenuItem(value: 1, child: Text('Voice')),
                        PopupMenuItem(value: 2, child: Text('Location')),
                      ],
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    Expanded(
                      child: TextField(
                        key: const Key('chat-message-input'),
                        controller: _text,
                        enabled: !effectiveDisabled && !state.sending,
                        maxLength: 4000,
                        minLines: 1,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: effectiveDisabled
                              ? 'This group is read only'
                              : 'Message',
                          counterText: '',
                          border: InputBorder.none,
                        ),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    IconButton(
                      key: const Key('record-voice-message'),
                      tooltip: 'Record voice message',
                      onPressed:
                          effectiveDisabled || state.sending || _mediaBusy
                          ? null
                          : _startRecording,
                      icon: const Icon(Icons.mic_none_rounded),
                    ),
                    IconButton.filled(
                      key: const Key('send-chat-message'),
                      tooltip: 'Send',
                      onPressed:
                          effectiveDisabled ||
                              state.sending ||
                              _text.text.trim().isEmpty
                          ? null
                          : _send,
                      icon: state.sending
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
              if (_recording)
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Cancel recording',
                      onPressed: () => _finishRecording(send: false),
                      icon: const Icon(Icons.delete_outline),
                    ),
                    const Icon(Icons.mic, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_recordingLabel())),
                    FilledButton.icon(
                      onPressed: () => _finishRecording(send: true),
                      icon: const Icon(Icons.send),
                      label: const Text('Send'),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    ),
  );

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    if (text.length > 4000) {
      Fluttertoast.showToast(
        msg: 'Messages can contain at most 4000 characters.',
      );
      return;
    }
    final sent = await context.read<ChatConversationCubit>().send(text);
    if (sent && mounted) _text.clear();
  }

  Future<void> _pickImage() async {
    if (_mediaBusy) return;
    setState(() => _mediaBusy = true);
    try {
      final selected = await _picker.pickImage(source: ImageSource.gallery);
      if (selected == null || !mounted) return;
      final length = await selected.length();
      if (length < 1 || length > ChatMediaValidation.imageMaxBytes) {
        Fluttertoast.showToast(msg: 'Images must be 5 MiB or smaller.');
        return;
      }
      final bytes = await selected.readAsBytes();
      final mime = ChatMediaValidation.imageMime(bytes);
      if (mime == null) {
        Fluttertoast.showToast(msg: 'Choose a valid JPEG, PNG, or WebP image.');
        return;
      }
      if (mounted) {
        await context.read<ChatConversationCubit>().sendImage(bytes);
      }
    } catch (_) {
      Fluttertoast.showToast(msg: 'The image could not be prepared.');
    } finally {
      if (mounted) setState(() => _mediaBusy = false);
    }
  }

  Future<void> _startRecording() async {
    if (_recording || _mediaBusy) return;
    setState(() => _mediaBusy = true);
    try {
      if (!await _recorder.hasPermission()) {
        Fluttertoast.showToast(
          msg: 'Microphone permission is required to record.',
        );
        return;
      }
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}${Platform.pathSeparator}shiftly-voice-${DateTime.now().microsecondsSinceEpoch}.m4a';
      _recordPath = path;
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      _recordStarted = DateTime.now();
      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || !_recording) return;
        final elapsed = DateTime.now().difference(_recordStarted!);
        setState(() {});
        if (elapsed.inMilliseconds >= ChatMediaValidation.voiceMaxDurationMs) {
          unawaited(_finishRecording(send: true));
        }
      });
      if (mounted) setState(() => _recording = true);
    } catch (_) {
      Fluttertoast.showToast(msg: 'Recording could not be started.');
    } finally {
      if (mounted) setState(() => _mediaBusy = false);
    }
  }

  Future<void> _finishRecording({required bool send}) async {
    if (!_recording) return;
    if (!send) {
      final discard = await ShiftlyChatDialog.confirm(
        context,
        title: 'Discard recording?',
        message: 'This voice recording will be permanently discarded.',
        confirmText: 'Discard',
        destructive: true,
      );
      if (!discard || !mounted || !_recording) return;
    }
    final started = _recordStarted;
    setState(() => _recording = false);
    _recordTimer?.cancel();
    String? path;
    try {
      if (!send) {
        await _recorder.cancel();
        return;
      }
      path = await _recorder.stop();
      final duration = started == null
          ? 0
          : DateTime.now().difference(started).inMilliseconds;
      if (path == null) throw const FormatException('Missing recording');
      final file = File(path);
      final bytes = await file.readAsBytes();
      if (!ChatMediaValidation.validVoice(
        bytes: bytes,
        mimeType: 'audio/mp4',
        durationMs: duration,
      )) {
        Fluttertoast.showToast(
          msg: 'The recording is empty, invalid, or too long.',
        );
        return;
      }
      if (mounted) {
        await context.read<ChatConversationCubit>().sendVoice(
          mimeType: 'audio/mp4',
          bytes: bytes,
          durationMs: duration,
        );
      }
    } catch (_) {
      Fluttertoast.showToast(msg: 'The recording could not be prepared.');
    } finally {
      if (path != null) {
        try {
          await File(path).delete();
        } catch (_) {}
      }
      _recordPath = null;
      _recordStarted = null;
    }
  }

  Future<void> _handleRecordingInterruption() async {
    if (!_recording) return;
    _recordTimer?.cancel();
    _recording = false;
    final path = _recordPath;
    _recordPath = null;
    _recordStarted = null;
    try {
      await _recorder.cancel();
    } catch (_) {}
    if (path != null) {
      try {
        await File(path).delete();
      } catch (_) {}
    }
    if (mounted) {
      setState(() {});
      Fluttertoast.showToast(msg: 'Recording was interrupted.');
    }
  }

  String _recordingLabel() {
    final elapsed = _recordStarted == null
        ? Duration.zero
        : DateTime.now().difference(_recordStarted!);
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds / 10:00';
  }

  Future<void> _shareLocation() async {
    if (_mediaBusy) return;
    setState(() => _mediaBusy = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        Fluttertoast.showToast(
          msg: 'Turn on location services to share a location.',
        );
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        Fluttertoast.showToast(
          msg: permission == LocationPermission.deniedForever
              ? 'Location permission is blocked in system settings.'
              : 'Location permission was denied.',
        );
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final location = ChatLocation(
        latitude: _sixDecimals(position.latitude),
        longitude: _sixDecimals(position.longitude),
      );
      if (!location.isValid || !mounted) return;
      final confirmed = await ShiftlyChatDialog.confirm(
        context,
        title: 'Share this location?',
        message: 'Your current coordinates will be visible to this group.',
        confirmText: 'Share',
      );
      if (confirmed && mounted) {
        await context.read<ChatConversationCubit>().sendLocation(location);
      }
    } on TimeoutException {
      Fluttertoast.showToast(msg: 'Location request timed out.');
    } catch (_) {
      Fluttertoast.showToast(msg: 'Your location is currently unavailable.');
    } finally {
      if (mounted) setState(() => _mediaBusy = false);
    }
  }

  double _sixDecimals(double value) =>
      (value * 1000000).roundToDouble() / 1000000;

  Future<void> _edit(ChatGroup group) async {
    final groups = context.read<ChatGroupsCubit>();
    await ShiftlyChatDialog.showBody<void>(
      context,
      body: _EditChatGroupDialog(
        group: group,
        groups: groups,
        onSuccess: () {
          if (mounted) context.read<ChatGroupDetailsCubit>().load();
        },
      ),
    );
  }

  Future<void> _archive(ChatGroup group) async {
    final confirm = await ShiftlyChatDialog.confirm(
      context,
      title: 'Archive group?',
      message: 'Messages remain readable, but no further changes or messages can be made.',
      confirmText: 'Archive',
      destructive: true,
    );
    if (!confirm || !mounted) return;
    final result = await context.read<ChatGroupsCubit>().archive(group.id);
    if (result == ChatMutationResult.success && mounted) {
      context.read<ChatGroupDetailsCubit>().load();
    }
  }

  Future<void> _showMembers(ChatGroup group) async {
    final manager = context.read<ChatGroupsCubit>().scope?.isManager == true;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<ChatGroupDetailsCubit>(),
        child: _MembersSheet(canManage: manager && !group.isArchived),
      ),
    );
  }
}
