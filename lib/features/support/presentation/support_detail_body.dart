import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import '../domain/support_models.dart';
import '../domain/support_repository.dart';
import 'support_image_preview.dart';
import 'support_reply_card.dart';
import 'support_reply_composer.dart';

class SupportDetailBody extends StatelessWidget {
  const SupportDetailBody({
    required this.ticket,
    required this.repository,
    required this.replyController,
    required this.sending,
    required this.error,
    required this.onReplyChanged,
    required this.onSend,
    super.key,
  });
  final SupportTicket ticket;
  final SupportRepository repository;
  final TextEditingController replyController;
  final bool sending;
  final String? error;
  final ValueChanged<String> onReplyChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      Text(ticket.title, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      Chip(label: Text(context.tr(supportStatusLabel(ticket.status)))),
      if (ticket.assignee != null)
        Text(
          context.tr('Responsible person: {name}', {'name': ticket.assignee!}),
        ),
      if (ticket.relatedLabel != null) Text(ticket.relatedLabel!),
      const SizedBox(height: 12),
      SelectableText(ticket.description),
      if (ticket.hasImage)
        SupportImagePreview(repository: repository, ticketId: ticket.id),
      const SizedBox(height: 20),
      Text(
        context.tr('Replies'),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      for (final r in ticket.replies) SupportReplyCard(reply: r),
      if (error != null)
        Text(
          context.tr(error!),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      const SizedBox(height: 16),
      SupportReplyComposer(
        canReply: ticket.canReply,
        controller: replyController,
        sending: sending,
        onChanged: onReplyChanged,
        onSend: onSend,
      ),
    ],
  );
}
