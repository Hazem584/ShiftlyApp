import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_composer_input.dart';

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
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: ListenableBuilder(
      listenable: textController,
      builder: (context, _) =>
          BlocBuilder<ChatConversationCubit, ChatConversationState>(
            builder: (context, state) {
              final effectiveDisabled =
                  disabled || loadingAccess || state.accessLost;
              final canSend =
                  !effectiveDisabled &&
                  !savingText &&
                  textController.text.trim().isNotEmpty &&
                  textController.text.trim().length <= 4000;
              final colors = Theme.of(context).colorScheme;
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
                                : context
                                      .read<ChatConversationCubit>()
                                      .retrySend,
                            child: Text(context.tr('Retry')),
                          ),
                        ],
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: context.tr('Attach'),
                            onPressed: effectiveDisabled || mediaBusy
                                ? null
                                : () async {
                                    final choice = await showModalBottomSheet<int>(
                                      context: context,
                                      showDragHandle: true,
                                      builder: (c) => SafeArea(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListTile(
                                              title: Text(
                                                c.tr('Share with the group'),
                                              ),
                                              subtitle: Text(
                                                c.tr('Choose an attachment.'),
                                              ),
                                            ),
                                            for (final (
                                                  value,
                                                  label,
                                                  subtitle,
                                                  icon,
                                                )
                                                in [
                                                  (
                                                    0,
                                                    'Photos',
                                                    'Choose an image',
                                                    Icons.image_outlined,
                                                  ),
                                                  (
                                                    1,
                                                    'Voice message',
                                                    'Record audio',
                                                    Icons.mic_none,
                                                  ),
                                                  (
                                                    2,
                                                    'Location',
                                                    'Share a location',
                                                    Icons.location_on_outlined,
                                                  ),
                                                  if (onPickDocument != null)
                                                    (
                                                      3,
                                                      'Document',
                                                      'PDF, Excel, CSV or text',
                                                      Icons
                                                          .description_outlined,
                                                    ),
                                                ])
                                              ListTile(
                                                leading: Icon(icon),
                                                title: Text(c.tr(label)),
                                                subtitle: Text(c.tr(subtitle)),
                                                onTap: () =>
                                                    Navigator.pop(c, value),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                    if (!context.mounted || choice == null) {
                                      return;
                                    }
                                    if (choice == 0) await onPickImage();
                                    if (choice == 1) await onStartRecording();
                                    if (choice == 2) await onShareLocation();
                                    if (choice == 3 && onPickDocument != null) {
                                      await onPickDocument!();
                                    }
                                  },
                            icon: Icon(Icons.add, color: colors.primary),
                          ),
                          Expanded(
                            child: ChatComposerInput(
                              controller: textController,
                              enabled: !effectiveDisabled,
                              canSend: canSend,
                              sendOnEnter: sendOnEnter,
                              hint: state.accessLost
                                  ? 'Chat access unavailable.'
                                  : loadingAccess
                                  ? 'Loading conversation…'
                                  : disabled
                                  ? 'This group is read only'
                                  : 'Message the group',
                              onChanged: onTextChanged,
                              onSend: onSend,
                            ),
                          ),
                          IconButton(
                            key: const Key('record-voice-message'),
                            tooltip: context.tr('Record voice message'),
                            onPressed: effectiveDisabled || mediaBusy
                                ? null
                                : onStartRecording,
                            icon: Icon(
                              Icons.mic_none_rounded,
                              color: colors.primary,
                            ),
                          ),
                          IconButton.filled(
                            key: const Key('send-chat-message'),
                            tooltip: context.tr('Send'),
                            style: IconButton.styleFrom(
                              foregroundColor: colors.onPrimary,
                              backgroundColor: colors.primary,
                              disabledForegroundColor: colors.onSurface
                                  .withValues(alpha: .38),
                              disabledBackgroundColor: colors.onSurface
                                  .withValues(alpha: .12),
                            ),
                            onPressed: canSend ? onSend : null,
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
                            label: Text(context.tr('Finish recording')),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
    ),
  );
}
