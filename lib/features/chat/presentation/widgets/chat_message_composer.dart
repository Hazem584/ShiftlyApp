import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';

class ChatMessageComposer extends StatelessWidget {
  const ChatMessageComposer({
    super.key,
    required this.disabled,
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
    required this.onStartRecording,
    required this.onShareLocation,
    required this.onFinishRecording,
  });
  final bool disabled, savingText, mediaBusy, recording, hasPreparedMedia;
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
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: BlocBuilder<ChatConversationCubit, ChatConversationState>(
      builder: (context, state) {
        final effectiveDisabled = disabled || state.accessLost;
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasPreparedMedia)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr(
                          'Prepared media was not saved. Retry to keep it.',
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: mediaBusy || effectiveDisabled
                          ? null
                          : onRetryPrepared,
                      child: Text(context.tr('Retry')),
                    ),
                  ],
                ),
              if (state.failedText != null)
                Row(
                  children: [
                    Expanded(
                      child: Text(context.tr('Message failed to send.')),
                    ),
                    TextButton(
                      onPressed: state.sending
                          ? null
                          : context.read<ChatConversationCubit>().retrySend,
                      child: Text(context.tr('Retry')),
                    ),
                  ],
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    PopupMenuButton<int>(
                      tooltip: context.tr('Attach'),
                      enabled: !effectiveDisabled && !mediaBusy,
                      onSelected: (value) {
                        if (value == 0) unawaited(onPickImage());
                        if (value == 1) unawaited(onStartRecording());
                        if (value == 2) unawaited(onShareLocation());
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 0,
                          child: Text(context.tr('Image')),
                        ),
                        PopupMenuItem(
                          value: 1,
                          child: Text(context.tr('Voice')),
                        ),
                        PopupMenuItem(
                          value: 2,
                          child: Text(context.tr('Location')),
                        ),
                      ],
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    Expanded(
                      child: TextField(
                        key: const Key('chat-message-input'),
                        controller: textController,
                        enabled: !effectiveDisabled,
                        maxLength: 4000,
                        minLines: 1,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: effectiveDisabled
                              ? 'This group is read only'
                              : 'Message',
                          counterText: '',
                          border: InputBorder.none,
                        ),
                        onChanged: (_) => onTextChanged(),
                        onSubmitted: (_) => onSend(),
                      ),
                    ),
                    IconButton(
                      key: const Key('record-voice-message'),
                      tooltip: context.tr('Record voice message'),
                      onPressed: effectiveDisabled || mediaBusy
                          ? null
                          : onStartRecording,
                      icon: const Icon(Icons.mic_none_rounded),
                    ),
                    IconButton.filled(
                      key: const Key('send-chat-message'),
                      tooltip: context.tr('Send'),
                      onPressed:
                          effectiveDisabled ||
                              savingText ||
                              textController.text.trim().isEmpty
                          ? null
                          : onSend,
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
              if (recording)
                Row(
                  children: [
                    IconButton(
                      tooltip: context.tr('Cancel recording'),
                      onPressed: () => onFinishRecording(send: false),
                      icon: const Icon(Icons.delete_outline),
                    ),
                    const Icon(Icons.mic, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(recordingLabel)),
                    FilledButton.icon(
                      onPressed: () => onFinishRecording(send: true),
                      icon: const Icon(Icons.send),
                      label: Text(context.tr('Send')),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    ),
  );
}
