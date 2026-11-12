import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import '../domain/support_models.dart';

class SupportTicketCard extends StatelessWidget {
  const SupportTicketCard({
    required this.ticket,
    required this.onTap,
    super.key,
  });
  final SupportTicket ticket;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      title: Text(ticket.title),
      subtitle: Text(
        [
          context.tr(supportStatusLabel(ticket.status)),
          if (ticket.relatedLabel != null) ticket.relatedLabel!,
          if (ticket.assignee != null) ticket.assignee!,
        ].join(' · '),
      ),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}
