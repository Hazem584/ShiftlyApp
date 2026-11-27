import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/presentation/chat_playback_coordinator.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_conversation_actions.dart';
import 'package:shiftly/features/chat/presentation/widgets/pending_media_bubble.dart';

List<Widget> buildChatPendingBubbles({
  required BuildContext context,
  required FeatureSessionScope scope,
  required String groupId,
  required List<PendingChatMessage> pendingList,
  required AudioPlayer player,
  required ChatPlaybackCoordinator? playback,
}) => [
  for (final pending in pendingList)
    PendingMediaBubble(
      key: ValueKey(pending.clientMessageId),
      pending: pending,
      player: player,
      playback: playback,
      cacheScope: ChatCacheScope.fromSession(scope, groupId),
      onRetry: (id) => context.read<ChatConversationCubit>().retryMedia(id),
      onCancel: (id) => confirmCancelChatPending(context, id),
    ),
];
