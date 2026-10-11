import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';

class CorrectionRequestCard extends StatelessWidget {
  const CorrectionRequestCard({
    super.key,
    required this.request,
    required this.timezone,
    this.onApprove,
    this.onDecline,
    this.busy = false,
  });
  final CorrectionRequest request;
  final String timezone;
  final VoidCallback? onApprove, onDecline;
  final bool busy;
  @override
  Widget build(BuildContext context) {
    String time(DateTime value) => WorkspaceTime.dateTime(
      value,
      timezone,
      locale: Localizations.localeOf(context).toString(),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(request.name, style: Theme.of(context).textTheme.titleMedium),
            Text(
              context.tr(switch (request.status) {
                'PENDING' => 'Pending review',
                'APPROVED' => 'Approved',
                _ => 'Declined',
              }),
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('Original times'),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Text('${time(request.originalIn)}\n${time(request.originalOut)}'),
            const SizedBox(height: 10),
            Text(
              context.tr('Requested times'),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Text('${time(request.requestedIn)}\n${time(request.requestedOut)}'),
            const Divider(),
            Text(request.reason),
            if (request.reviewNote != null) Text(request.reviewNote!),
            if (request.reviewer != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  context.tr('Reviewed by {name}', {'name': request.reviewer!}),
                ),
              ),
            if (request.reviewedAt != null) Text(time(request.reviewedAt!)),
            if (request.status == 'PENDING' && onApprove != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: busy ? null : onApprove,
                      icon: const Icon(Icons.check),
                      label: Text(context.tr('Approve')),
                    ),
                    OutlinedButton.icon(
                      onPressed: busy ? null : onDecline,
                      icon: const Icon(Icons.close),
                      label: Text(context.tr('Decline')),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
