import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_group_details_cubit.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/chat/presentation/dialogs/edit_chat_group_dialog.dart';
import 'package:shiftly/features/chat/presentation/dialogs/shiftly_chat_dialog.dart';

export 'chat_conversation_group_nav.dart';

Future<void> editChatGroupFromConversation(
  BuildContext context,
  ChatGroup group,
) async {
  final groups = context.read<ChatGroupsCubit>();
  await ShiftlyChatDialog.showBody<void>(
    context,
    body: EditChatGroupDialog(
      group: group,
      groups: groups,
      onSuccess: () {
        if (context.mounted) context.read<ChatGroupDetailsCubit>().load();
      },
    ),
  );
}

Future<void> archiveChatGroupFromConversation(
  BuildContext context,
  ChatGroup group,
) async {
  final confirm = await ShiftlyChatDialog.confirm(
    context,
    title: 'Archive group?',
    message:
        'Messages remain readable, but no further changes or messages can be made.',
    confirmText: 'Archive',
    destructive: true,
  );
  if (!confirm || !context.mounted) return;
  final result = await context.read<ChatGroupsCubit>().archive(group.id);
  if (result == ChatMutationResult.success && context.mounted) {
    await context.read<ChatGroupDetailsCubit>().load();
  }
}
