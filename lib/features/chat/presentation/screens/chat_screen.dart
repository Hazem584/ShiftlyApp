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
import 'package:shiftly/features/chat/presentation/dialogs/shiftly_chat_dialog.dart';
import 'package:shiftly/features/chat/presentation/widgets/messages/shiftly_chat_message_list.dart';
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
      child: _ChatView(groupId: groupId),
    );
  }
}

String _nameInitials(String value) => value
    .trim()
    .split(RegExp(r'\s+'))
    .where((part) => part.isNotEmpty)
    .take(2)
    .map((part) => part[0].toUpperCase())
    .join();

class _ChatView extends StatefulWidget {
  const _ChatView({required this.groupId});
  final String groupId;
  @override
  State<_ChatView> createState() => _ChatViewState();
}

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

  String _initials(String value) {
    final words = value.trim().split(RegExp(r'\s+'));
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }

  Widget _messages() =>
      BlocBuilder<ChatConversationCubit, ChatConversationState>(
        builder: (context, state) {
          final scope = context.read<ChatGroupsCubit>().scope!;
          final pending = state.pending;
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
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
                    onLoadOlder: context
                        .read<ChatConversationCubit>()
                        .loadOlder,
                    onRetry: context.read<ChatConversationCubit>().load,
                    messageBuilder: (message, mine) => _MessageBubble(
                      message: message,
                      mine: mine,
                      repository: context.read<ChatRepository>(),
                      workspaceId: scope.workspaceId,
                      timezone: scope.timezone,
                      player: _player,
                    ),
                  ),
                ),
              ),
              if (pending.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 230),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                    itemCount: pending.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (_, index) => PendingMediaBubble(
                      pending: pending[index],
                      onRetry: (id) =>
                          context.read<ChatConversationCubit>().retryMedia(id),
                      onCancel: _confirmCancelPending,
                    ),
                  ),
                ),
            ],
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
                    IconButton(
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
  Widget build(BuildContext context) {
    final bubble = Container(
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
    );
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 570),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!mine) ...[
              CircleAvatar(
                radius: 15,
                backgroundImage: message.sender.avatarUrl == null
                    ? null
                    : NetworkImage(message.sender.avatarUrl!),
                child: message.sender.avatarUrl == null
                    ? Text(
                        _nameInitials(message.sender.displayName),
                        style: Theme.of(context).textTheme.labelSmall,
                      )
                    : null,
              ),
              const SizedBox(width: 7),
            ],
            Flexible(child: bubble),
          ],
        ),
      ),
    );
  }

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

class _RemoteImage extends StatefulWidget {
  const _RemoteImage({
    required this.repository,
    required this.workspaceId,
    required this.message,
  });
  final ChatRepository repository;
  final String workspaceId;
  final ChatMessage message;

  @override
  State<_RemoteImage> createState() => _RemoteImageState();
}

class _RemoteImageState extends State<_RemoteImage> {
  late Future<ChatMediaUrl> _media;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  void _resolve() {
    _media = widget.repository.mediaUrl(
      widget.workspaceId,
      widget.message.groupId,
      widget.message.id,
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ChatMediaUrl>(
    future: _media,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return SizedBox(
          width: 220,
          height: 140,
          child: Center(
            child: TextButton.icon(
              onPressed: () => setState(_resolve),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry image'),
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const SizedBox(
          width: 220,
          height: 140,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final url = snapshot.data!.url;
      final heroTag = 'chat-image-${widget.message.id}';
      return InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _FullScreenImage(url: url, heroTag: heroTag),
          ),
        ),
        borderRadius: BorderRadius.circular(14),
        child: Hero(
          tag: heroTag,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320, maxHeight: 360),
              child: Image.network(
                url.toString(),
                fit: BoxFit.cover,
                cacheWidth: 960,
                errorBuilder: (_, _, _) => const SizedBox(
                  width: 220,
                  height: 140,
                  child: Center(child: Icon(Icons.broken_image_outlined)),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _FullScreenImage extends StatelessWidget {
  const _FullScreenImage({required this.url, required this.heroTag});
  final Uri url;
  final String heroTag;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      foregroundColor: Colors.white,
      backgroundColor: Colors.black,
      title: const Text('Image'),
    ),
    body: Center(
      child: Hero(
        tag: heroTag,
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 5,
          child: Image.network(
            url.toString(),
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        ),
      ),
    ),
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
      final buffering =
          active &&
          (state.data?.processingState == ProcessingState.loading ||
              state.data?.processingState == ProcessingState.buffering);
      final duration = widget.message.attachment?.durationMs ?? 0;
      return SizedBox(
        width: 230,
        child: Row(
          children: [
            IconButton.filledTonal(
              tooltip: playing ? 'Pause voice message' : 'Play voice message',
              onPressed: _loading || buffering
                  ? null
                  : () => _toggle(active, playing),
              icon: _loading || buffering
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      state.data?.processingState ==
                                  ProcessingState.completed &&
                              active
                          ? Icons.replay
                          : playing
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StreamBuilder<Duration>(
                stream: widget.player.positionStream,
                builder: (_, position) {
                  final shown = active
                      ? position.data?.inMilliseconds
                                .clamp(0, duration)
                                .toInt() ??
                            0
                      : 0;
                  final progress = duration == 0 ? 0.0 : shown / duration;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _VoiceWaveform(progress: progress),
                      const SizedBox(height: 4),
                      Text(
                        '${_duration(shown)} / ${_duration(duration)}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
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

class _VoiceWaveform extends StatelessWidget {
  const _VoiceWaveform({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const heights = <double>[8, 15, 11, 20, 13, 18, 9, 16, 12, 19, 10, 14];
    return Row(
      children: [
        for (var index = 0; index < heights.length; index++)
          Expanded(
            child: Container(
              height: heights[index],
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: index / heights.length <= progress
                    ? colors.primary
                    : colors.outlineVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
      ],
    );
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

class PendingMediaBubble extends StatelessWidget {
  const PendingMediaBubble({
    required this.pending,
    required this.onRetry,
    required this.onCancel,
    super.key,
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
          if (pending.mediaType == PendingChatMediaType.image)
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
                  Icon(Icons.image_outlined),
                  SizedBox(width: 8),
                  Text('Image'),
                ],
              )
          else
            Row(
              children: [
                const Icon(Icons.mic),
                const SizedBox(width: 8),
                const Text('Voice message'),
                if (pending.durationMs != null) ...[
                  const SizedBox(width: 8),
                  Text(_durationLabel(pending.durationMs!)),
                ],
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

  String _durationLabel(int durationMs) {
    final duration = Duration(milliseconds: durationMs);
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
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
    final confirmed = await ShiftlyChatDialog.confirm(
      context,
      title: 'Remove member?',
      message: '${member.displayName} will lose access to this group.',
      confirmText: 'Remove',
      destructive: true,
    );
    if (confirmed && context.mounted) {
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
    var submitting = false;
    String? failure;
    final details = context.read<ChatGroupDetailsCubit>();
    await ShiftlyChatDialog.showBody<void>(
      context,
      body: StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Add members'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (submitting) const LinearProgressIndicator(),
                if (failure != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      failure!,
                      style: TextStyle(
                        color: Theme.of(dialogContext).colorScheme.error,
                      ),
                    ),
                  ),
                Flexible(
                  child: choices.isEmpty
                      ? const Text(
                          'No other active workspace members are available.',
                        )
                      : ListView(
                          shrinkWrap: true,
                          children: [
                            for (final employee in choices)
                              CheckboxListTile(
                                value: selected.contains(employee.id),
                                title: Text(employee.displayName),
                                onChanged: submitting
                                    ? null
                                    : (value) => setState(
                                        () => value == true
                                            ? selected.add(employee.id)
                                            : selected.remove(employee.id),
                                      ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selected.isEmpty || submitting
                  ? null
                  : () async {
                      setState(() {
                        submitting = true;
                        failure = null;
                      });
                      final added = await details.addMembers(selected.toList());
                      if (!dialogContext.mounted) return;
                      if (added) {
                        Navigator.pop(dialogContext);
                      } else {
                        setState(() {
                          submitting = false;
                          failure =
                              details.state.failure?.message ??
                              'Could not add members.';
                        });
                      }
                    },
              child: Text(submitting ? 'Adding…' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }
}
