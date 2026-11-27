import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_conversation_item_builders.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_conversation_top_banners.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_conversation_view_mixin.dart';
import 'package:shiftly/features/chat/presentation/widgets/messages/shiftly_chat_message_list.dart';

Widget buildChatConversationMessagesSection(
  ChatConversationViewMixin viewState,
) => BlocBuilder<ChatConversationCubit, ChatConversationState>(
  builder: (context, state) {
    final scope = context.read<ChatGroupsCubit>().scope;
    if (scope == null || state.accessLost) {
      return Center(child: Text(context.tr('Chat access unavailable.')));
    }
    final cubit = context.read<ChatConversationCubit>();
    final groupId = viewState.widget.groupId;
    return Column(
      children: [
        ...buildChatMessageSectionBanners(context, state, cubit),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => cubit.load(refresh: true),
            child: ShiftlyChatMessageList(
              key: ValueKey('${scope.userId}:${scope.workspaceId}:$groupId'),
              focusMessageId: viewState.focusMessageId,
              messages: state.messages,
              currentMembershipId: scope.membershipId,
              loading: state.loading,
              failureMessage:
                  state.messages.isEmpty ? state.failure?.message : null,
              hasMore: state.hasMore,
              loadingOlder: state.loadingOlder,
              onLoadOlder: cubit.loadOlder,
              onRetry: cubit.load,
              trailingMessages: buildChatPendingBubbles(
                context: context,
                scope: scope,
                groupId: groupId,
                pendingList: state.pending,
                player: viewState.player,
                playback: viewState.playback,
              ),
              messageBuilder: (msg, mine, showSender) =>
                  buildChatConversationBubble(
                    context: context,
                    scope: scope,
                    groupId: groupId,
                    message: msg,
                    mine: mine,
                    showSender: showSender,
                    player: viewState.player,
                    playback: viewState.playback,
                    onReply: viewState.setReply,
                  ),
            ),
          ),
        ),
      ],
    );
  },
);
