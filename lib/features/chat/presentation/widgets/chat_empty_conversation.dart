import 'package:flutter/material.dart';

class ChatEmptyConversation extends StatelessWidget {
  const ChatEmptyConversation({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.forum_outlined, size: 44),
          SizedBox(height: 12),
          Text(
            'No messages yet. Start the conversation.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
