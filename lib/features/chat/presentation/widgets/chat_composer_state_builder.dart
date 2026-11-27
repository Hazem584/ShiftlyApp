import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';

class ChatComposerStateBuilder extends StatelessWidget {
  const ChatComposerStateBuilder({
    required this.textController,
    required this.disabled,
    required this.savingText,
    required this.builder,
    super.key,
  });

  final TextEditingController textController;
  final bool disabled, savingText;
  final Widget Function(
    BuildContext context,
    ChatConversationState state,
    bool disabled,
    bool canSend,
  )
  builder;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: ListenableBuilder(
      listenable: textController,
      builder: (context, _) =>
          BlocBuilder<ChatConversationCubit, ChatConversationState>(
            builder: (context, state) {
              final effectiveDisabled = disabled || state.accessLost;
              final text = textController.text.trim();
              final canSend =
                  !effectiveDisabled &&
                  !savingText &&
                  text.isNotEmpty &&
                  text.length <= 4000;
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
                child: builder(context, state, effectiveDisabled, canSend),
              );
            },
          ),
    ),
  );
}

String chatComposerHint(bool lostAccess, bool loadingAccess, bool readOnly) {
  if (lostAccess) return 'Chat access unavailable.';
  if (loadingAccess) return 'Loading conversation…';
  if (readOnly) return 'This group is read only';
  return 'Message the group';
}
