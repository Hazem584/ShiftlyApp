import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/domain/services/message_read_status.dart';
import 'package:shiftly/features/chat/presentation/chat_playback_coordinator.dart';
import 'package:shiftly/features/chat/presentation/controllers/chat_media_capture.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_group_details_cubit.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/chat/presentation/dialogs/edit_chat_group_dialog.dart';
import 'package:shiftly/features/chat/presentation/dialogs/shiftly_chat_dialog.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_members_sheet.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_message_bubble.dart';
import 'package:shiftly/features/chat/presentation/widgets/messages/shiftly_chat_message_list.dart';
import 'package:shiftly/features/chat/presentation/widgets/pending_media_bubble.dart';

import 'chat_message_composer.dart';

class ChatConversationView extends StatefulWidget {
  const ChatConversationView({super.key, required this.groupId});
  final String groupId;
  @override
  State<ChatConversationView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatConversationView>
    with WidgetsBindingObserver {
  late final ChatMediaCapture _media;
  void _refreshMedia() {
    if (mounted) setState(() {});
  }

  final _text = TextEditingController();

  final _player = AudioPlayer();
  ChatPlaybackCoordinator? _playback;

  Timer? _accessTimer;

  bool _savingText = false;

  @override
  void initState() {
    super.initState();
    _media = ChatMediaCapture(context)..addListener(_refreshMedia);
    WidgetsBinding.instance.addObserver(this);
    final cache = context.read<ChatGroupsCubit>().mediaCache;
    if (cache != null) _playback = ChatPlaybackCoordinator(_player, cache);
    _accessTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        unawaited(context.read<ChatGroupDetailsCubit>().load());
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
      if (_media.recording) unawaited(_media.handleRecordingInterruption());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _accessTimer?.cancel();

    _media.removeListener(_refreshMedia);
    _media.dispose();
    _playback?.close();
    _player.dispose();

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
          _media.clearPreparedMedia();
          unawaited(_player.stop());
          unawaited(_player.setAudioSources([]));
          unawaited(_media.handleRecordingInterruption());
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
                  ChatMessageComposer(
                    disabled: group?.isArchived == true,
                    loadingAccess: group == null,
                    textController: _text,
                    savingText: _savingText,
                    mediaBusy: _media.mediaBusy,
                    recording: _media.recording,
                    hasPreparedMedia: _media.hasPreparedMedia,
                    recordingLabel: _media.recordingLabel(),
                    onTextChanged: () => setState(() {}),
                    onSend: _send,
                    onRetryPrepared: _media.retryPreparedMedia,
                    onPickImage: _media.pickImage,
                    onStartRecording: _media.startRecording,
                    onShareLocation: _media.shareLocation,
                    onFinishRecording: _media.finishRecording,
                  ),
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
                          readByAll: messageReadByAll(
                            message,
                            context.read<ChatGroupDetailsCubit>().state.group,
                          ),
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
