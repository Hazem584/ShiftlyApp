import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class ChatComposerRetry extends StatelessWidget {
  const ChatComposerRetry({required this.message, this.onRetry, super.key});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(context.tr(message))),
      TextButton(onPressed: onRetry, child: Text(context.tr('Retry'))),
    ],
  );
}
