import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class ChatLoadError extends StatelessWidget {
  const ChatLoadError({
    super.key,
    required this.message,
    required this.onRetry,
  });
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.tr(message), textAlign: TextAlign.center),
        TextButton(onPressed: onRetry, child: Text(context.tr('Retry'))),
      ],
    ),
  );
}
