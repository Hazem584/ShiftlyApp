import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class ChatComposerToolbar extends StatelessWidget {
  const ChatComposerToolbar({
    required this.input,
    required this.onAttach,
    required this.onStartRecording,
    required this.onSend,
    super.key,
  });

  final Widget input;
  final VoidCallback? onAttach, onStartRecording, onSend;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: context.tr('Attach'),
            onPressed: onAttach,
            icon: Icon(Icons.add, color: colors.primary),
          ),
          Expanded(child: input),
          IconButton(
            key: const Key('record-voice-message'),
            tooltip: context.tr('Record voice message'),
            onPressed: onStartRecording,
            icon: Icon(Icons.mic_none_rounded, color: colors.primary),
          ),
          IconButton.filled(
            key: const Key('send-chat-message'),
            tooltip: context.tr('Send'),
            style: IconButton.styleFrom(
              foregroundColor: colors.onPrimary,
              backgroundColor: colors.primary,
              disabledForegroundColor: colors.onSurface.withValues(alpha: .38),
              disabledBackgroundColor: colors.onSurface.withValues(alpha: .12),
            ),
            onPressed: onSend,
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}
