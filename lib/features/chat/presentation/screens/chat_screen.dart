import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/features/chat/data/chat_member_loader.dart';
import 'package:shiftly/features/chat/data/chat_models.dart';
import 'package:shiftly/features/chat/data/chat_media_validation.dart';
import 'package:shiftly/features/chat/data/chat_realtime.dart';
import 'package:shiftly/features/chat/data/chat_repository.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_group_details_cubit.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/employees/data/employee_repository.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({required this.groupId, super.key});
  final String groupId;

  @override
  Widget build(BuildContext context) {
    final groups = context.read<ChatGroupsCubit>();
    final scope = groups.scope;
    if (scope == null) {
      return const Scaffold(
        body: Center(child: Text('Chat session is no longer active.')),
      );
    }
    final repository = context.read<ChatRepository>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ChatGroupDetailsCubit(
            repository,
            onChanged: () => groups.load(refresh: true),
          )..bind(scope, groupId),
        ),
        BlocProvider(
          create: (_) => ChatConversationCubit(
            repository,
            context.read<ChatRealtime>(),
            onChanged: () => groups.load(refresh: true),
          )..bind(scope, groupId),
        ),
      ],
      child: const _ChatView(),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView();
  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  bool _loadingOlder = false;
  bool _initialPositioned = false;
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
    _scroll.addListener(_onScroll);
    _recordState = _recorder.onStateChanged().listen((value) {
      if ((value == RecordState.stop || value == RecordState.pause) &&
          _recording) {
        unawaited(_handleRecordingInterruption());
      }
    });
  }

  void _onScroll() async {
    if (!_scroll.hasClients || _scroll.offset > 120 || _loadingOlder) return;
    final cubit = context.read<ChatConversationCubit>();
    if (!cubit.state.hasMore) return;
    _loadingOlder = true;
    final oldExtent = _scroll.position.maxScrollExtent;
    await cubit.loadOlder();
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          final added = _scroll.position.maxScrollExtent - oldExtent;
          _scroll.jumpTo(
            (_scroll.offset + added).clamp(0, _scroll.position.maxScrollExtent),
          );
        }
      });
    }
    _loadingOlder = false;
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    unawaited(_recordState?.cancel());
    unawaited(_recorder.cancel());
    _recorder.dispose();
    _player.dispose();
    _scroll.dispose();
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
          title: Text(group?.name ?? 'Chat'),
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
              const ColoredBox(
                color: Color(0xfffff3cd),
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.archive_outlined, size: 18),
                      SizedBox(width: 8),
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

  Widget
  _messages() => BlocConsumer<ChatConversationCubit, ChatConversationState>(
    listenWhen: (before, after) =>
        after.messages.length > before.messages.length && !after.loadingOlder,
    listener: (_, state) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) return;
        if (!_initialPositioned) {
          _initialPositioned = true;
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        } else if (_scroll.position.maxScrollExtent - _scroll.offset < 500) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          );
        }
      });
    },
    builder: (context, state) {
      if (state.loading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (state.messages.isEmpty && state.failure != null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.failure!.message),
              TextButton(
                onPressed: context.read<ChatConversationCubit>().load,
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
      if (state.messages.isEmpty) {
        return const Center(
          child: Text('No messages yet. Start the conversation.'),
        );
      }
      final membershipId = context.read<ChatGroupsCubit>().scope!.membershipId;
      final pending = state.pending;
      return RefreshIndicator(
        onRefresh: () =>
            context.read<ChatConversationCubit>().load(refresh: true),
        child: ListView.builder(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          itemCount:
              state.messages.length +
              pending.length +
              (state.loadingOlder ? 1 : 0),
          itemBuilder: (_, index) {
            if (state.loadingOlder && index == 0) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final offset = state.loadingOlder ? index - 1 : index;
            if (offset >= state.messages.length) {
              return _PendingMediaBubble(
                pending: pending[offset - state.messages.length],
                onRetry: (id) =>
                    context.read<ChatConversationCubit>().retryMedia(id),
                onCancel: (id) =>
                    context.read<ChatConversationCubit>().cancelPending(id),
              );
            }
            final message = state.messages[offset];
            return _MessageBubble(
              message: message,
              mine: message.sender.membershipId == membershipId,
              repository: context.read<ChatRepository>(),
              workspaceId: context.read<ChatGroupsCubit>().scope!.workspaceId,
              timezone: context.read<ChatGroupsCubit>().scope!.timezone,
              player: _player,
            );
          },
        ),
      );
    },
  );

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
              Row(
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
                      PopupMenuItem(value: 0, child: Text('Photo')),
                      PopupMenuItem(value: 1, child: Text('Voice message')),
                      PopupMenuItem(value: 2, child: Text('Share location')),
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
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    key: const Key('send-chat-message'),
                    tooltip: 'Send',
                    onPressed: effectiveDisabled || state.sending
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
        await context.read<ChatConversationCubit>().sendMedia(
          type: 'IMAGE',
          mimeType: mime,
          bytes: bytes,
        );
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
        await context.read<ChatConversationCubit>().sendMedia(
          type: 'VOICE',
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
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Share this location?'),
          content: const Text(
            'Your current coordinates will be visible to this group.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Share'),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
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
    await showDialog<void>(
      context: context,
      builder: (_) => _EditChatGroupDialog(
        group: group,
        groups: groups,
        onSuccess: () {
          if (mounted) context.read<ChatGroupDetailsCubit>().load();
        },
      ),
    );
  }

  Future<void> _archive(ChatGroup group) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Archive group?'),
        content: const Text(
          'Messages remain readable, but no further changes or messages can be made.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
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

class _EditChatGroupDialog extends StatefulWidget {
  const _EditChatGroupDialog({
    required this.group,
    required this.groups,
    required this.onSuccess,
  });

  final ChatGroup group;
  final ChatGroupsCubit groups;
  final VoidCallback onSuccess;

  @override
  State<_EditChatGroupDialog> createState() => _EditChatGroupDialogState();
}

class _EditChatGroupDialogState extends State<_EditChatGroupDialog> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final Object? _scope;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.group.name);
    _description = TextEditingController(text: widget.group.description);
    _scope = widget.groups.scope;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<ChatGroupsCubit, ChatGroupsState>(
        bloc: widget.groups,
        listenWhen: (_, _) => widget.groups.scope != _scope,
        listener: (context, _) => _close(context),
        buildWhen: (before, after) => before.mutating != after.mutating,
        builder: (context, groupState) {
          final submitting = groupState.mutating;
          return AlertDialog(
            title: const Text('Edit group'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const Key('edit-group-name'),
                  controller: _name,
                  maxLength: 80,
                  enabled: !submitting,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  key: const Key('edit-group-description'),
                  controller: _description,
                  maxLength: 500,
                  enabled: !submitting,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
            actions: [
              TextButton(
                key: const Key('edit-group-cancel'),
                onPressed: submitting ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                key: const Key('edit-group-submit'),
                onPressed: submitting ? null : () => _submit(context),
                child: submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        },
      );

  Future<void> _submit(BuildContext context) async {
    final name = _name.text.trim();
    final description = _description.text.trim();
    if (name.isEmpty) {
      Fluttertoast.showToast(msg: 'Enter a group name.');
      return;
    }
    if (name.length > 80 || description.length > 500) {
      Fluttertoast.showToast(
        msg: 'Check the group name and description lengths.',
      );
      return;
    }
    if (widget.groups.scope != _scope) {
      if (context.mounted) _close(context);
      return;
    }
    final result = await widget.groups.update(
      widget.group.id,
      name: name,
      description: description,
    );
    if (!context.mounted) return;
    if (result == ChatMutationResult.success) {
      _close(context);
      widget.onSuccess();
    } else if (result == ChatMutationResult.stale ||
        widget.groups.scope != _scope) {
      _close(context);
    } else if (result == ChatMutationResult.failure) {
      Fluttertoast.showToast(
        msg: widget.groups.state.failure?.message ?? 'Could not update group.',
      );
    }
  }

  void _close(BuildContext context) {
    if (_closing) return;
    _closing = true;
    Navigator.pop(context);
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.mine,
    required this.repository,
    required this.workspaceId,
    required this.timezone,
    required this.player,
  });
  final ChatMessage message;
  final bool mine;
  final ChatRepository repository;
  final String workspaceId;
  final String timezone;
  final AudioPlayer player;
  @override
  Widget build(BuildContext context) => Align(
    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 520),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: mine
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!mine)
            Text(
              message.sender.displayName,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          _content(context),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              WorkspaceTime.time(message.createdAt, timezone),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _content(BuildContext context) => switch (message.type) {
    'TEXT' => Text(message.text ?? ''),
    'IMAGE' => _RemoteImage(
      repository: repository,
      workspaceId: workspaceId,
      message: message,
    ),
    'VOICE' => _VoiceMessage(
      repository: repository,
      workspaceId: workspaceId,
      message: message,
      player: player,
    ),
    'LOCATION' => _LocationCard(location: message.location),
    _ => const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.help_outline, size: 18),
        SizedBox(width: 8),
        Text('Unsupported message'),
      ],
    ),
  };
}

class _RemoteImage extends StatelessWidget {
  const _RemoteImage({
    required this.repository,
    required this.workspaceId,
    required this.message,
  });
  final ChatRepository repository;
  final String workspaceId;
  final ChatMessage message;

  @override
  Widget build(BuildContext context) => FutureBuilder<ChatMediaUrl>(
    future: repository.mediaUrl(workspaceId, message.groupId, message.id),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const SizedBox(
          width: 220,
          height: 140,
          child: Center(child: Icon(Icons.broken_image_outlined)),
        );
      }
      if (!snapshot.hasData) {
        return const SizedBox(
          width: 220,
          height: 140,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320, maxHeight: 360),
        child: Image.network(
          snapshot.data!.url.toString(),
          fit: BoxFit.cover,
          cacheWidth: 960,
          errorBuilder: (_, _, _) => const SizedBox(
            width: 220,
            height: 140,
            child: Center(child: Icon(Icons.broken_image_outlined)),
          ),
        ),
      );
    },
  );
}

class _VoiceMessage extends StatefulWidget {
  const _VoiceMessage({
    required this.repository,
    required this.workspaceId,
    required this.message,
    required this.player,
  });
  final ChatRepository repository;
  final String workspaceId;
  final ChatMessage message;
  final AudioPlayer player;

  @override
  State<_VoiceMessage> createState() => _VoiceMessageState();
}

class _VoiceMessageState extends State<_VoiceMessage> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) => StreamBuilder<PlayerState>(
    stream: widget.player.playerStateStream,
    builder: (context, state) {
      final active =
          widget.player.audioSource != null &&
          widget.player.sequenceState.currentSource?.tag == widget.message.id;
      final playing = active && widget.player.playing;
      final duration = widget.message.attachment?.durationMs ?? 0;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: playing ? 'Pause voice message' : 'Play voice message',
            onPressed: _loading ? null : () => _toggle(active, playing),
            icon: _loading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(playing ? Icons.pause : Icons.play_arrow),
          ),
          StreamBuilder<Duration>(
            stream: widget.player.positionStream,
            builder: (_, position) {
              final shown = active ? position.data?.inMilliseconds ?? 0 : 0;
              return Text('${_duration(shown)} / ${_duration(duration)}');
            },
          ),
        ],
      );
    },
  );

  Future<void> _toggle(bool active, bool playing) async {
    try {
      if (active && playing) {
        await widget.player.pause();
        return;
      }
      if (active &&
          widget.player.processingState != ProcessingState.completed) {
        await widget.player.play();
        return;
      }
      setState(() => _loading = true);
      final media = await widget.repository.mediaUrl(
        widget.workspaceId,
        widget.message.groupId,
        widget.message.id,
      );
      await widget.player.setAudioSource(
        AudioSource.uri(media.url, tag: widget.message.id),
      );
      await widget.player.play();
    } catch (_) {
      Fluttertoast.showToast(msg: 'This voice message is unavailable.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _duration(int milliseconds) {
    final seconds = (milliseconds / 1000).floor();
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.location});
  final ChatLocation? location;

  @override
  Widget build(BuildContext context) {
    final value = location;
    if (value == null || !value.isValid) {
      return const Text('Location unavailable');
    }
    return InkWell(
      onTap: () async {
        final uri = Uri.https('www.google.com', '/maps/search/', {
          'api': '1',
          'query': '${value.latitude},${value.longitude}',
        });
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          Fluttertoast.showToast(msg: 'No maps application is available.');
        }
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(child: Icon(Icons.location_on_outlined)),
          title: Text(value.label ?? 'Shared location'),
          subtitle: value.address == null
              ? const Text('Open in maps')
              : Text(value.address!),
          trailing: const Icon(Icons.open_in_new, size: 18),
        ),
      ),
    );
  }
}

class _PendingMediaBubble extends StatelessWidget {
  const _PendingMediaBubble({
    required this.pending,
    required this.onRetry,
    required this.onCancel,
  });
  final PendingChatMessage pending;
  final Future<void> Function(String) onRetry;
  final Future<void> Function(String) onCancel;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 320),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pending.previewBytes != null)
            Image.memory(
              pending.previewBytes!,
              height: 160,
              width: 260,
              cacheWidth: 720,
              fit: BoxFit.cover,
            )
          else
            const Row(
              children: [
                Icon(Icons.mic),
                SizedBox(width: 8),
                Text('Voice message'),
              ],
            ),
          const SizedBox(height: 8),
          if (pending.status != ChatUploadState.failed)
            LinearProgressIndicator(
              value: pending.status == ChatUploadState.preparing
                  ? null
                  : pending.progress.clamp(0, 1),
            ),
          Text(switch (pending.status) {
            ChatUploadState.preparing => 'Preparing…',
            ChatUploadState.uploading => 'Uploading…',
            ChatUploadState.finalizing => 'Sending…',
            ChatUploadState.sent => 'Sent',
            ChatUploadState.failed =>
              pending.failure?.message ?? 'Upload failed',
            ChatUploadState.cancelled => 'Cancelled',
          }),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (pending.status == ChatUploadState.failed)
                TextButton(
                  onPressed: () => onRetry(pending.clientMessageId),
                  child: const Text('Retry'),
                ),
              TextButton(
                onPressed: () => onCancel(pending.clientMessageId),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _MembersSheet extends StatelessWidget {
  const _MembersSheet({required this.canManage});
  final bool canManage;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ChatGroupDetailsCubit, ChatGroupDetailsState>(
        builder: (context, state) {
          final group = state.group;
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
              ),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * .65,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Members',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        if (canManage && group != null)
                          IconButton(
                            onPressed: () => _add(context, group),
                            tooltip: 'Add members',
                            icon: const Icon(Icons.person_add_alt_1),
                          ),
                      ],
                    ),
                    if (state.mutating) const LinearProgressIndicator(),
                    Expanded(
                      child: group == null
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              itemCount: group.members.length,
                              itemBuilder: (_, index) {
                                final member = group.members[index];
                                return ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.person_outline),
                                  ),
                                  title: Text(member.displayName),
                                  subtitle: member.email == null
                                      ? null
                                      : Text(member.email!),
                                  trailing: canManage
                                      ? IconButton(
                                          tooltip: 'Remove member',
                                          onPressed: state.mutating
                                              ? null
                                              : () => _remove(context, member),
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                          ),
                                        )
                                      : null,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

  Future<void> _remove(BuildContext context, ChatMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text('${member.displayName} will lose access to this group.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<ChatGroupDetailsCubit>().removeMember(
        member.membershipId,
      );
    }
  }

  Future<void> _add(BuildContext context, ChatGroup group) async {
    final scope = context.read<ChatGroupsCubit>().scope;
    if (scope == null) return;
    List<Employee> employees;
    try {
      employees = await loadActiveChatMembers(
        context.read<EmployeeRepository>(),
        scope,
      );
    } catch (_) {
      Fluttertoast.showToast(msg: 'Could not load active workspace members.');
      return;
    }
    if (!context.mounted || context.read<ChatGroupsCubit>().scope != scope) {
      return;
    }
    final existing = group.members.map((m) => m.membershipId).toSet();
    final choices = employees.where((e) => !existing.contains(e.id)).toList();
    final selected = <String>{};
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: const Text('Add members'),
          content: SizedBox(
            width: 420,
            child: choices.isEmpty
                ? const Text('No other active workspace members are available.')
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final employee in choices)
                        CheckboxListTile(
                          value: selected.contains(employee.id),
                          title: Text(employee.displayName),
                          onChanged: (value) => setState(
                            () => value == true
                                ? selected.add(employee.id)
                                : selected.remove(employee.id),
                          ),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<ChatGroupDetailsCubit>().addMembers(selected.toList());
    }
  }
}
