import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class ChatEmptyConversation extends StatelessWidget {
  const ChatEmptyConversation({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.forum_outlined, size: 44),
          const SizedBox(height: 12),
          Text(
            context.tr('No messages yet. Start the conversation.'),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
