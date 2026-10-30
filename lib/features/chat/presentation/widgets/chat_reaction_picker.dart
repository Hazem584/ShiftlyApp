import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

class ChatReactionPicker extends StatelessWidget {
  const ChatReactionPicker({
    required this.onReact,
    required this.canRemove,
    super.key,
  });
  final ValueChanged<String?> onReact;
  final bool canRemove;
  static Future<void> show(
    BuildContext context,
    ValueChanged<String?> onReact, {
    bool canRemove = false,
  }) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => ChatReactionPicker(
      canRemove: canRemove,
      onReact: (emoji) {
        Navigator.pop(sheet);
        onReact(emoji);
      },
    ),
  );
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.tr('React to message'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Wrap(
            spacing: 4,
            children: [
              for (final emoji in ChatReaction.choices)
                IconButton(
                  tooltip: context.tr('React with {emoji}', {'emoji': emoji}),
                  icon: Text(emoji, style: const TextStyle(fontSize: 28)),
                  onPressed: () => onReact(emoji),
                ),
            ],
          ),
          if (canRemove)
            TextButton(
              onPressed: () => onReact(null),
              child: Text(context.tr('Remove reaction')),
            ),
        ],
      ),
    ),
  );
}
