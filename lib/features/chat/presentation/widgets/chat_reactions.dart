import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

class ChatReactions extends StatelessWidget {
  const ChatReactions({
    required this.reactions,
    required this.membershipId,
    this.onReact,
    super.key,
  });
  final List<ChatReaction> reactions;
  final String? membershipId;
  final ValueChanged<String?>? onReact;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 4,
    runSpacing: 2,
    children: [
      for (final emoji in ChatReaction.choices)
        if (reactions.any((r) => r.emoji == emoji))
          FilterChip(
            visualDensity: VisualDensity.compact,
            label: Text(
              '$emoji ${reactions.where((r) => r.emoji == emoji).length}',
            ),
            tooltip: context.tr('React with {emoji}', {'emoji': emoji}),
            selected: reactions.any(
              (r) => r.emoji == emoji && r.membershipId == membershipId,
            ),
            onSelected: onReact == null
                ? null
                : (_) => onReact!(
                    reactions.any(
                          (r) =>
                              r.emoji == emoji &&
                              r.membershipId == membershipId,
                        )
                        ? null
                        : emoji,
                  ),
          ),
    ],
  );
}
