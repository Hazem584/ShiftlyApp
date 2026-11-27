import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/presentation/chat_playback_coordinator.dart';
import 'package:shiftly/features/chat/presentation/controllers/chat_media_capture.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_group_details_cubit.dart';

import 'chat_conversation_actions.dart';
import 'chat_conversation_view.dart';

mixin ChatConversationViewMixin on State<ChatConversationView> {
  late final ChatMediaCapture media;
  final textController = TextEditingController();
  final player = AudioPlayer();
  ChatPlaybackCoordinator? playback;
  Timer? accessTimer;
  bool savingText = false;
  ChatMessage? reply;
  String? focusMessageId;

  void refreshView() {
    if (mounted) setState(() {});
  }

  void setReply(ChatMessage? value) => setState(() => reply = value);
  void setSavingText(bool value) => setState(() => savingText = value);
  void setFocusMessage(String? id) => setState(() => focusMessageId = id);

  void handleLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(context.read<ChatGroupDetailsCubit>().load());
      unawaited(context.read<ChatConversationCubit>().load(refresh: true));
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      playback != null ? playback!.pause() : unawaited(player.pause());
      if (media.recording) unawaited(media.handleRecordingInterruption());
    }
  }

  void handleAccessLost() {
    textController.clear();
    reply = null;
    media.clearPreparedMedia();
    unawaited(player.stop());
    unawaited(player.setAudioSources([]));
    unawaited(media.handleRecordingInterruption());
    setState(() {});
  }

  Future<void> sendText() => submitChatConversationText(this);
  Future<void> searchMessages(bool pinned) =>
      openChatConversationSearch(this, pinned);
}
