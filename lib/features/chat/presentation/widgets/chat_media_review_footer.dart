import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class ChatMediaReviewFooter extends StatelessWidget {
  const ChatMediaReviewFooter({
    required this.kind,
    required this.action,
    required this.onConfirm,
    required this.onCancel,
    super.key,
  });

  final String kind, action;
  final VoidCallback onConfirm, onCancel;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FilledButton(
        key: const Key('confirm-chat-media'),
        onPressed: onConfirm,
        child: Text(context.tr(action)),
      ),
      TextButton(
        onPressed: onCancel,
        child: Text(
          context.tr(
            kind == 'IMAGE'
                ? 'Choose a different image'
                : kind == 'DOCUMENT'
                ? 'Choose a different document'
                : kind == 'VOICE'
                ? 'Discard recording'
                : 'Cancel',
          ),
        ),
      ),
    ],
  );
}
