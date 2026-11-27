import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/presentation/controllers/chat_conversation_tools.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';
import 'package:shiftly/features/chat/presentation/dialogs/shiftly_chat_dialog.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_conversation_view_mixin.dart';

Future<void> confirmCancelChatPending(
  BuildContext context,
  String clientId,
) async {
  final confirmed = await ShiftlyChatDialog.confirm(
    context,
    title: 'Cancel upload?',
    message: 'The pending media will be removed from this conversation.',
    confirmText: 'Cancel upload',
    destructive: true,
  );
  if (confirmed && context.mounted) {
    await context.read<ChatConversationCubit>().cancelPending(clientId);
  }
}

Future<void> submitChatConversationText(ChatConversationViewMixin state) async {
  if (state.savingText) return;
  final input = state.textController.text, text = input.trim();
  if (text.isEmpty) return;
  if (text.length > 4000) {
    Fluttertoast.showToast(
      msg: state.context.tr('Messages can contain at most 4000 characters.'),
    );
    return;
  }
  state.setSavingText(true);
  final replyId = state.reply?.id;
  final ok = await state.context.read<ChatConversationCubit>().send(
    text,
    replyToMessageId: replyId,
  );
  if (!state.mounted) return;
  if (ok && state.textController.text == input) state.textController.clear();
  if (ok && state.reply?.id == replyId) state.reply = null;
  state.setSavingText(false);
  if (!ok && state.mounted) {
    Fluttertoast.showToast(
      msg: state.context.tr(
        'Message was not saved. Keep your input and retry.',
      ),
    );
  }
}

Future<void> openChatConversationSearch(
  ChatConversationViewMixin state,
  bool pinned,
) async {
  final context = state.context;
  final msg = await ChatConversationTools.search(
    context,
    state.widget.groupId,
    pinned,
  );
  if (!context.mounted || !state.mounted || msg == null) return;
  final found = await ChatConversationTools.loadMessage(
    context.read<ChatConversationCubit>(),
    msg.id,
  );
  if (!context.mounted || !state.mounted) return;
  if (!found) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr('Could not open this message. Retry the search.'),
        ),
      ),
    );
    return;
  }
  state.setFocusMessage(null);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (state.mounted) state.setFocusMessage(msg.id);
  });
}
