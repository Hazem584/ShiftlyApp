import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_group_details_cubit.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';

import 'chat_conversation_body.dart';
import 'chat_conversation_group_actions.dart';
import 'chat_conversation_header.dart';
import 'chat_conversation_messages_section.dart';
import 'chat_conversation_view_mixin.dart';

Widget buildChatConversationScaffold(
  BuildContext context,
  ChatConversationViewMixin state,
  ChatGroupDetailsState details,
) {
  if (context.read<ChatConversationCubit>().state.accessLost) {
    return Scaffold(
      body: Center(child: Text(context.tr('Chat access unavailable.'))),
    );
  }
  final group = details.group;
  final manager = context.read<ChatGroupsCubit>().scope?.isManager == true;
  return Scaffold(
    appBar: ChatConversationHeader(
      group: group,
      manager: manager,
      onInformation: () {
        if (group != null) {
          openChatGroupInformation(context, group, state.searchMessages);
        }
      },
      onSearch: () => state.searchMessages(false),
      onPinned: () => state.searchMessages(true),
      onMembers: () {
        if (group != null) showChatGroupMembers(context, group);
      },
      onEdit: () {
        if (group != null) editChatGroupFromConversation(context, group);
      },
      onArchive: () {
        if (group != null) archiveChatGroupFromConversation(context, group);
      },
    ),
    body: Column(
      children: [
        ...buildChatConversationTopBanners(context, details),
        Expanded(child: buildChatConversationMessagesSection(state)),
        ...buildChatConversationBottomSection(context, state, group),
      ],
    ),
  );
}
