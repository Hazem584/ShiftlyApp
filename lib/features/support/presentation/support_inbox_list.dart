import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';

import '../domain/support_models.dart';
import 'support_ticket_card.dart';

class SupportInboxList extends StatelessWidget {
  const SupportInboxList({
    required this.tickets,
    required this.loading,
    required this.hasNext,
    required this.error,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onOpenTicket,
    super.key,
  });
  final List<SupportTicket> tickets;
  final bool loading, hasNext;
  final String? error;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final ValueChanged<SupportTicket> onOpenTicket;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Text(
          context.tr(
            'Your reports stay here so you can follow the status and support replies.',
          ),
        ),
        if (error != null) ...[
          Text(
            context.tr(error!),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          TextButton(onPressed: onRefresh, child: Text(context.tr('Retry'))),
        ],
        if (loading && tickets.isEmpty) const AppContentLoading(),
        if (!loading && tickets.isEmpty && error == null)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(context.tr('No support reports yet.')),
          ),
        for (final ticket in tickets)
          SupportTicketCard(ticket: ticket, onTap: () => onOpenTicket(ticket)),
        if (hasNext)
          TextButton(
            onPressed: loading ? null : onLoadMore,
            child: Text(context.tr('Load more')),
          ),
      ],
    ),
  );
}
