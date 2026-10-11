import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/domain/entities/chat_message.dart';

String replyMessageText(ChatMessage message) =>
    message.text ??
    switch (message.type) {
      'IMAGE' => 'Photo',
      'VOICE' => 'Voice message',
      'LOCATION' => 'Location',
      _ => 'Message',
    };

class ChatReplyPreview extends StatelessWidget {
  const ChatReplyPreview({
    super.key,
    required this.name,
    required this.text,
    this.onCancel,
  });
  final String name, text;
  final VoidCallback? onCancel;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 4, 8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: .5),
      border: BorderDirectional(
        start: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 3,
        ),
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                context.tr(text),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (onCancel != null)
          IconButton(
            tooltip: context.tr('Cancel reply'),
            onPressed: onCancel,
            icon: const Icon(Icons.close, size: 18),
          ),
      ],
    ),
  );
}
