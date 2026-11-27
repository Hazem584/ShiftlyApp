import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';

import 'chat_attachment_picker.dart';
import 'chat_composer_input.dart';
import 'chat_composer_retry.dart';
import 'chat_composer_state_builder.dart';
import 'chat_composer_toolbar.dart';
import 'chat_recording_controls.dart';

class ChatMessageComposer extends StatelessWidget {
  const ChatMessageComposer({
    super.key,
    required this.disabled,
    this.loadingAccess = false,
    this.sendOnEnter = kIsWeb,
    required this.textController,
    required this.savingText,
    required this.mediaBusy,
    required this.recording,
    required this.hasPreparedMedia,
    required this.recordingLabel,
    required this.onTextChanged,
    required this.onSend,
    required this.onRetryPrepared,
    required this.onPickImage,
    this.onPickDocument,
    required this.onStartRecording,
    required this.onShareLocation,
    required this.onFinishRecording,
  });
  final Future<void> Function()? onPickDocument;
  final bool disabled, savingText, mediaBusy, recording, hasPreparedMedia;
  final bool loadingAccess;
  final bool sendOnEnter;
  final TextEditingController textController;
  final String recordingLabel;
  final VoidCallback onTextChanged;
  final Future<void> Function() onSend,
      onRetryPrepared,
      onPickImage,
      onStartRecording,
      onShareLocation;
  final Future<void> Function({required bool send}) onFinishRecording;
  @override
  Widget build(BuildContext context) => ChatComposerStateBuilder(
    textController: textController,
    disabled: disabled || loadingAccess,
    savingText: savingText,
    builder: (context, state, effectiveDisabled, canSend) {
      final mediaEnabled = !effectiveDisabled && !mediaBusy;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasPreparedMedia)
            ChatComposerRetry(
              message: 'Prepared media was not saved. Retry to keep it.',
              onRetry: mediaEnabled ? onRetryPrepared : null,
            ),
          if (state.failedText != null)
            ChatComposerRetry(
              message: 'Message failed to send.',
              onRetry: state.sending
                  ? null
                  : context.read<ChatConversationCubit>().retrySend,
            ),
          ChatComposerToolbar(
            onAttach: mediaEnabled
                ? () => showChatAttachmentPicker(
                    context,
                    onPickImage: onPickImage,
                    onStartRecording: onStartRecording,
                    onShareLocation: onShareLocation,
                    onPickDocument: onPickDocument,
                  )
                : null,
            onStartRecording: mediaEnabled ? onStartRecording : null,
            onSend: canSend ? onSend : null,
            input: ChatComposerInput(
              controller: textController,
              enabled: !effectiveDisabled,
              canSend: canSend,
              sendOnEnter: sendOnEnter,
              hint: chatComposerHint(state.accessLost, loadingAccess, disabled),
              onChanged: onTextChanged,
              onSend: onSend,
            ),
          ),
          if (recording)
            ChatRecordingControls(
              recordingLabel: recordingLabel,
              onFinishRecording: onFinishRecording,
            ),
        ],
      );
    },
  );
}
