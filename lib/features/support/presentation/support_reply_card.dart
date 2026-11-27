import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import '../domain/support_models.dart';

class SupportReplyCard extends StatelessWidget {
  const SupportReplyCard({required this.reply, super.key});
  final SupportReply reply;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reply.author.isEmpty
                ? context.tr(reply.staff ? 'Support team' : 'You')
                : reply.author,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            reply.createdAt.toLocal().toString().split('.').first,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          SelectableText(reply.body),
        ],
      ),
    ),
  );
}
