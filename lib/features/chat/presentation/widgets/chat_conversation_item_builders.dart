import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/domain/services/message_read_status.dart';
import 'package:shiftly/features/chat/presentation/chat_playback_coordinator.dart';
import 'package:shiftly/features/chat/presentation/controllers/chat_conversation_tools.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_group_details_cubit.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_message_bubble.dart';

export 'chat_conversation_pending_builder.dart';

Widget buildChatConversationBubble({
  required BuildContext context,
  required FeatureSessionScope scope,
  required String groupId,
  required ChatMessage message,
  required bool mine,
  required bool showSender,
  required AudioPlayer player,
  required ChatPlaybackCoordinator? playback,
  required ValueChanged<ChatMessage> onReply,
}) {
  final group = context.read<ChatGroupDetailsCubit>().state.group;
  final archived = group?.isArchived == true;
  return ChatMessageBubble(
    message: message,
    membershipId: scope.membershipId,
    onReact: message.deletedAt != null || group?.isArchived != false
        ? null
        : (emoji) => unawaited(
            ChatConversationTools.react(context, groupId, message, emoji),
          ),
    mine: mine,
    showSender: showSender,
    repository: context.read<ChatRepository>(),
    workspaceId: scope.workspaceId,
    timezone: scope.timezone,
    player: player,
    playback: playback,
    readByAll: messageReadByAll(message, group),
    onReply: archived ? null : () => onReply(message),
    onPin: scope.isManager && !archived
        ? () => ChatConversationTools.pin(context, groupId, message)
        : null,
  );
}
