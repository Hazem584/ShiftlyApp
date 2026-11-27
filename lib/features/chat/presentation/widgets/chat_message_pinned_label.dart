import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class ChatMessagePinnedLabel extends StatelessWidget {
  const ChatMessagePinnedLabel({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.push_pin, size: 14),
        const SizedBox(width: 4),
        Text(
          context.tr('Pinned'),
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    ),
  );
}
