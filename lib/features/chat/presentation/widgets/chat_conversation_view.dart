import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/domain/services/chat_media_validation.dart';
import 'package:shiftly/features/chat/presentation/chat_playback_coordinator.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_group_details_cubit.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/chat/presentation/dialogs/edit_chat_group_dialog.dart';
import 'package:shiftly/features/chat/presentation/dialogs/shiftly_chat_dialog.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_members_sheet.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_message_bubble.dart';
import 'package:shiftly/features/chat/presentation/widgets/messages/shiftly_chat_message_list.dart';
import 'package:shiftly/features/chat/presentation/widgets/pending_media_bubble.dart';

class ChatConversationView extends StatefulWidget {
  const ChatConversationView({super.key, required this.groupId});
  final String groupId;
  @override
  State<ChatConversationView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatConversationView>
    with WidgetsBindingObserver {
  final _text = TextEditingController();
  final _picker = ImagePicker();
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  ChatPlaybackCoordinator? _playback;
  StreamSubscription<RecordState>? _recordState;
  Timer? _recordTimer;
  Timer? _accessTimer;
  DateTime? _recordStarted;
  bool _recording = false;
  bool _mediaBusy = false;
  bool _savingText = false;
  Uint8List? _preparedImage;
  String? _preparedVoicePath;
  int? _preparedVoiceDuration;
  String? _recordPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final cache = context.read<ChatGroupsCubit>().mediaCache;
    if (cache != null) _playback = ChatPlaybackCoordinator(_player, cache);
    _accessTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        unawaited(context.read<ChatGroupDetailsCubit>().load());
      }
    });
    _recordState = _recorder.onStateChanged().listen((value) {
      if ((value == RecordState.stop || value == RecordState.pause) &&
          _recording) {
        unawaited(_handleRecordingInterruption());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(context.read<ChatGroupDetailsCubit>().load());
      unawaited(context.read<ChatConversationCubit>().load(refresh: true));
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (_playback != null) {
        _playback!.pause();
      } else {
        unawaited(_player.pause());
      }
      if (_recording) unawaited(_handleRecordingInterruption());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordTimer?.cancel();
    _accessTimer?.cancel();
    unawaited(_recordState?.cancel());
    unawaited(_recorder.cancel());
    _recorder.dispose();
    _playback?.close();
    _player.dispose();
    if (_preparedVoicePath case final path?) {
      unawaited(File(path).delete().catchError((Object _) => File(path)));
    }
    if (_recordPath case final path?) {
      unawaited(File(path).delete().catchError((Object _) => File(path)));
    }
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<ChatConversationCubit, ChatConversationState>(
        listenWhen: (previous, current) =>
            !previous.accessLost && current.accessLost,
        listener: (_, _) {
          _text.clear();
          _preparedImage = null;
          if (_preparedVoicePath case final path?) {
            unawaited(File(path).delete().catchError((Object _) => File(path)));
          }
          _preparedVoicePath = null;
          _preparedVoiceDuration = null;
          unawaited(_player.stop());
          unawaited(_player.setAudioSources([]));
          unawaited(_handleRecordingInterruption());
          setState(() {});
        },
        child: BlocBuilder<ChatGroupDetailsCubit, ChatGroupDetailsState>(
          builder: (context, details) {
            if (context.read<ChatConversationCubit>().state.accessLost) {
              return Scaffold(
                body: Center(
                  child: Text(context.tr('Chat access unavailable.')),
                ),
              );
            }
            final group = details.group;
            final manager =
                context.read<ChatGroupsCubit>().scope?.isManager == true;
            return Scaffold(
              appBar: AppBar(
                titleSpacing: 0,
                title: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      child: Text(
                        _initials(group?.name ?? context.tr('Chat')),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group?.name ?? context.tr('Chat'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (group != null)
                            Text(
                              group.isArchived
                                  ? context.tr('{value1} members · Read only', {
                                      'value1': (group.memberCount).toString(),
                                    })
                                  : context.tr('{value1} members', {
                                      'value1': (group.memberCount).toString(),
                                    }),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    tooltip: context.tr('Group members'),
                    onPressed: group == null ? null : () => _showMembers(group),
                    icon: const Icon(Icons.group_outlined),
                  ),
                  if (manager && group != null && !group.isArchived)
                    PopupMenuButton<String>(
                      onSelected: (value) =>
                          value == 'edit' ? _edit(group) : _archive(group),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(context.tr('Edit group')),
                        ),
                        PopupMenuItem(
                          value: 'archive',
                          child: Text(context.tr('Archive group')),
                        ),
                      ],
                    ),
                ],
              ),
              body: Column(
                children: [
                  if (details.failure != null)
                    MaterialBanner(
                      content: Text(context.tr(details.failure!.message)),
                      actions: [
                        TextButton(
                          onPressed: context.read<ChatGroupDetailsCubit>().load,
                          child: Text(context.tr('Retry')),
                        ),
                      ],
                    ),
                  if (group?.isArchived == true)
                    ColoredBox(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            const Icon(Icons.archive_outlined, size: 18),
                            Text(context.tr('Archived group — read only')),
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
        ),
      );

  String _initials(String value) {
    final words = value.trim().split(RegExp(r'\s+'));
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }

  Widget _messages() =>
      BlocBuilder<ChatConversationCubit, ChatConversationState>(
        builder: (context, state) {
          final scope = context.read<ChatGroupsCubit>().scope;
          if (scope == null || state.accessLost) {
            return Center(child: Text(context.tr('Chat access unavailable.')));
          }
          return Column(
            children: [
              if (state.historyGap)
                TextButton(
                  onPressed: state.loadingOlder
                      ? null
                      : context.read<ChatConversationCubit>().loadOlder,
                  child: Text(
                    context.tr('History has a gap — load missing messages'),
                  ),
                ),
              if (state.failure != null && state.messages.isNotEmpty)
                TextButton(
                  onPressed: () =>
                      context.read<ChatConversationCubit>().load(refresh: true),
                  child: Text(context.tr('Refresh unavailable — retry')),
                ),
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
                    trailingMessages: [
                      for (final pending in state.pending)
                        PendingMediaBubble(
                          key: ValueKey(pending.clientMessageId),
                          pending: pending,
                          player: _player,
                          playback: _playback,
                          cacheScope: ChatCacheScope.fromSession(
                            scope,
                            widget.groupId,
                          ),
                          onRetry: (id) => context
                              .read<ChatConversationCubit>()
                              .retryMedia(id),
                          onCancel: _confirmCancelPending,
                        ),
                    ],
                    messageBuilder: (message, mine, showSender) =>
                        ChatMessageBubble(
                          message: message,
                          mine: mine,
                          showSender: showSender,
                          repository: context.read<ChatRepository>(),
                          workspaceId: scope.workspaceId,
                          timezone: scope.timezone,
                          player: _player,
                          playback: _playback,
                        ),
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
              if (_preparedImage != null || _preparedVoicePath != null)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr(
                          'Prepared media was not saved. Retry to keep it.',
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _mediaBusy || effectiveDisabled
                          ? null
                          : _retryPreparedMedia,
                      child: Text(context.tr('Retry')),
                    ),
                  ],
                ),
              if (state.failedText != null)
                Row(
                  children: [
                    Expanded(
                      child: Text(context.tr('Message failed to send.')),
                    ),
                    TextButton(
                      onPressed: state.sending
                          ? null
                          : context.read<ChatConversationCubit>().retrySend,
                      child: Text(context.tr('Retry')),
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
                      tooltip: context.tr('Attach'),
                      enabled: !effectiveDisabled && !_mediaBusy,
                      onSelected: (value) {
                        if (value == 0) unawaited(_pickImage());
                        if (value == 1) unawaited(_startRecording());
                        if (value == 2) unawaited(_shareLocation());
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 0,
                          child: Text(context.tr('Image')),
                        ),
                        PopupMenuItem(
                          value: 1,
                          child: Text(context.tr('Voice')),
                        ),
                        PopupMenuItem(
                          value: 2,
                          child: Text(context.tr('Location')),
                        ),
                      ],
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    Expanded(
                      child: TextField(
                        key: const Key('chat-message-input'),
                        controller: _text,
                        enabled: !effectiveDisabled,
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
                      tooltip: context.tr('Record voice message'),
                      onPressed: effectiveDisabled || _mediaBusy
                          ? null
                          : _startRecording,
                      icon: const Icon(Icons.mic_none_rounded),
                    ),
                    IconButton.filled(
                      key: const Key('send-chat-message'),
                      tooltip: context.tr('Send'),
                      onPressed:
                          effectiveDisabled ||
                              _savingText ||
                              _text.text.trim().isEmpty
                          ? null
                          : _send,
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
              if (_recording)
                Row(
                  children: [
                    IconButton(
                      tooltip: context.tr('Cancel recording'),
                      onPressed: () => _finishRecording(send: false),
                      icon: const Icon(Icons.delete_outline),
                    ),
                    const Icon(Icons.mic, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_recordingLabel())),
                    FilledButton.icon(
                      onPressed: () => _finishRecording(send: true),
                      icon: const Icon(Icons.send),
                      label: Text(context.tr('Send')),
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
    if (_savingText) return;
    final input = _text.text;
    final text = _text.text.trim();
    if (text.isEmpty) return;
    if (text.length > 4000) {
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: context.tr('Messages can contain at most 4000 characters.'),
      );
      return;
    }
    setState(() => _savingText = true);
    final accepted = await context.read<ChatConversationCubit>().send(text);
    if (mounted) {
      if (accepted && _text.text == input) _text.clear();
      setState(() => _savingText = false);
      if (!accepted) {
        if (!mounted) return;
        Fluttertoast.showToast(
          msg: context.tr('Message was not saved. Keep your input and retry.'),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    if (_mediaBusy) return;
    setState(() => _mediaBusy = true);
    try {
      final selected = await _picker.pickImage(source: ImageSource.gallery);
      if (selected == null || !mounted) return;
      final length = await selected.length();
      if (length < 1 || length > ChatMediaValidation.imageMaxBytes) {
        if (!mounted) return;
        Fluttertoast.showToast(
          msg: context.tr('Images must be 5 MiB or smaller.'),
        );
        return;
      }
      final bytes = await selected.readAsBytes();
      final mime = ChatMediaValidation.imageMime(bytes);
      if (mime == null) {
        if (!mounted) return;
        Fluttertoast.showToast(
          msg: context.tr('Choose a valid JPEG, PNG, or WebP image.'),
        );
        return;
      }
      if (mounted) {
        _preparedImage = bytes;
        final id = await context.read<ChatConversationCubit>().sendImage(bytes);
        if (id != null) _preparedImage = null;
      }
    } catch (_) {
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: context.tr('The image could not be prepared.'),
      );
    } finally {
      if (mounted) setState(() => _mediaBusy = false);
    }
  }

  Future<void> _startRecording() async {
    if (_recording || _mediaBusy) return;
    setState(() => _mediaBusy = true);
    try {
      if (!await _recorder.hasPermission()) {
        if (!mounted) return;
        Fluttertoast.showToast(
          msg: context.tr('Microphone permission is required to record.'),
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
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: context.tr('Recording could not be started.'),
      );
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
    bool accepted = false;
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
        if (!mounted) return;
        Fluttertoast.showToast(
          msg: context.tr('The recording is empty, invalid, or too long.'),
        );
        return;
      }
      if (mounted) {
        _preparedVoicePath = path;
        _preparedVoiceDuration = duration;
        final id = await context.read<ChatConversationCubit>().sendVoice(
          mimeType: 'audio/mp4',
          bytes: bytes,
          durationMs: duration,
        );
        accepted = id != null;
        if (accepted) {
          _preparedVoicePath = null;
          _preparedVoiceDuration = null;
        }
      }
    } catch (_) {
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: context.tr('The recording could not be prepared.'),
      );
    } finally {
      if (path != null && (accepted || _preparedVoicePath != path)) {
        try {
          await File(path).delete();
        } catch (_) {}
      }
      _recordPath = null;
      _recordStarted = null;
      if (mounted) setState(() {});
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
      if (!mounted) return;
      Fluttertoast.showToast(msg: context.tr('Recording was interrupted.'));
    }
  }

  Future<void> _retryPreparedMedia() async {
    setState(() => _mediaBusy = true);
    try {
      final conversation = context.read<ChatConversationCubit>();
      if (_preparedImage case final bytes?) {
        if (await conversation.sendImage(bytes) != null) _preparedImage = null;
      }
      if (_preparedVoicePath case final path?) {
        final bytes = await File(path).readAsBytes();
        if (await conversation.sendVoice(
              bytes: bytes,
              mimeType: 'audio/mp4',
              durationMs: _preparedVoiceDuration!,
            ) !=
            null) {
          await File(path).delete();
          _preparedVoicePath = null;
          _preparedVoiceDuration = null;
        }
      }
    } catch (_) {
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: context.tr(
          'Media could not be saved. Retry when storage is available.',
        ),
      );
    } finally {
      if (mounted) setState(() => _mediaBusy = false);
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
        if (!mounted) return;
        Fluttertoast.showToast(
          msg: context.tr('Turn on location services to share a location.'),
        );
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        Fluttertoast.showToast(
          msg: context.tr(
            permission == LocationPermission.deniedForever
                ? 'Location permission is blocked in system settings.'
                : 'Location permission was denied.',
          ),
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
      if (!mounted) return;
      Fluttertoast.showToast(msg: context.tr('Location request timed out.'));
    } catch (_) {
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: context.tr('Your location is currently unavailable.'),
      );
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
      body: EditChatGroupDialog(
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
        child: ChatMembersSheet(canManage: manager && !group.isArchived),
      ),
    );
  }
}
