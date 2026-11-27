import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class SupportReplyComposer extends StatelessWidget {
  const SupportReplyComposer({
    required this.canReply,
    required this.controller,
    required this.sending,
    required this.onChanged,
    required this.onSend,
    super.key,
  });
  final bool canReply;
  final TextEditingController controller;
  final bool sending;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    if (!canReply) return Text(context.tr('This report is closed.'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          enabled: !sending,
          minLines: 2,
          maxLines: 6,
          maxLength: 5000,
          onChanged: onChanged,
          decoration: InputDecoration(labelText: context.tr('Write a reply')),
        ),
        FilledButton.icon(
          onPressed: sending ? null : onSend,
          icon: const Icon(Icons.send_outlined),
          label: Text(context.tr(sending ? 'Sending…' : 'Send reply')),
        ),
      ],
    );
  }
}
