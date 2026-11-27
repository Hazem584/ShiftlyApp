import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

void showChatMessageActions(
  BuildContext context, {
  required ChatMessage message,
  required VoidCallback? onReply,
  required VoidCallback? onPin,
  required VoidCallback? onReact,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: Text(c.tr('Message actions'))),
          if (onReact != null)
            ListTile(
              leading: const Icon(Icons.add_reaction_outlined),
              title: Text(c.tr('React to message')),
              onTap: () {
                Navigator.pop(c);
                onReact();
              },
            ),
          if (onReply != null)
            ListTile(
              leading: const Icon(Icons.reply),
              title: Text(c.tr('Reply')),
              onTap: () {
                Navigator.pop(c);
                onReply();
              },
            ),
          if (message.text?.isNotEmpty == true)
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(c.tr('Copy text')),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.text!));
                Navigator.pop(c);
              },
            ),
          if (onPin != null)
            ListTile(
              leading: const Icon(Icons.push_pin_outlined),
              title: Text(
                c.tr(
                  message.pinnedAt == null ? 'Pin message' : 'Unpin message',
                ),
              ),
              onTap: () {
                Navigator.pop(c);
                onPin();
              },
            ),
        ],
      ),
    ),
  );
}
