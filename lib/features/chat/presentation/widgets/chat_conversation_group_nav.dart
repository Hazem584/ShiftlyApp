import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/theme/collaboration_appearance.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_group_details_cubit.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/chat/presentation/screens/chat_group_information_screen.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_conversation_group_actions.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_members_sheet.dart';

Future<void> openChatGroupInformation(
  BuildContext context,
  ChatGroup group,
  void Function(bool pinned) onSearch,
) async {
  final details = context.read<ChatGroupDetailsCubit>();
  await Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (infoContext) => ChatGroupInformationScreen(
        details: details,
        manager: context.read<ChatGroupsCubit>().scope?.isManager == true,
        onMembers: () =>
            showChatGroupMembers(context, details.state.group ?? group),
        onSearch: () {
          Navigator.pop(infoContext);
          onSearch(false);
        },
        onPinned: () {
          Navigator.pop(infoContext);
          onSearch(true);
        },
        onEdit: () => editChatGroupFromConversation(
          context,
          details.state.group ?? group,
        ),
        onArchive: () => archiveChatGroupFromConversation(
          context,
          details.state.group ?? group,
        ),
      ),
    ),
  );
}

Future<void> showChatGroupMembers(BuildContext context, ChatGroup group) async {
  final manager = context.read<ChatGroupsCubit>().scope?.isManager == true;
  final details = context.read<ChatGroupDetailsCubit>();
  final groups = context.read<ChatGroupsCubit>();
  await Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: details),
          BlocProvider.value(value: groups),
        ],
        child: CollaborationAppearance(
          child: ChatMembersSheet(canManage: manager && !group.isArchived),
        ),
      ),
    ),
  );
}
