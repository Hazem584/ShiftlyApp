import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/features/chat/presentation/chat_playback_coordinator.dart';
import 'package:shiftly/features/chat/presentation/controllers/chat_media_capture.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_group_details_cubit.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';

import 'chat_conversation_scaffold.dart';
import 'chat_conversation_view_mixin.dart';

class ChatConversationView extends StatefulWidget {
  const ChatConversationView({super.key, required this.groupId});
  final String groupId;
  @override
  State<ChatConversationView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatConversationView>
    with WidgetsBindingObserver, ChatConversationViewMixin {
  @override
  void initState() {
    super.initState();
    media = ChatMediaCapture(context)..addListener(refreshView);
    WidgetsBinding.instance.addObserver(this);
    final cache = context.read<ChatGroupsCubit>().mediaCache;
    if (cache != null) playback = ChatPlaybackCoordinator(player, cache);
    accessTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        unawaited(context.read<ChatGroupDetailsCubit>().load());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      handleLifecycleState(state);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    accessTimer?.cancel();
    media.removeListener(refreshView);
    media.dispose();
    playback?.close();
    player.dispose();
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<ChatConversationCubit, ChatConversationState>(
        listenWhen: (p, c) => !p.accessLost && c.accessLost,
        listener: (_, _) => handleAccessLost(),
        child: BlocBuilder<ChatGroupDetailsCubit, ChatGroupDetailsState>(
          builder: (context, details) =>
              buildChatConversationScaffold(context, this, details),
        ),
      );
}
