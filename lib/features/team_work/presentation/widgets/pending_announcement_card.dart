import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';

class PendingAnnouncementCard extends StatelessWidget {
  const PendingAnnouncementCard({
    super.key,
    required this.announcement,
    required this.timezone,
    required this.busy,
    required this.onRead,
  });
  final TeamAnnouncement announcement;
  final String timezone;
  final bool busy;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.campaign_outlined, color: colors.onPrimaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    announcement.title,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: colors.onPrimaryContainer),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${announcement.author} · ${WorkspaceTime.dateTime(announcement.createdAt, timezone, locale: Localizations.localeOf(context).toString())}',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onPrimaryContainer),
            ),
            const SizedBox(height: 12),
            SelectableText(
              announcement.body,
              style: TextStyle(color: colors.onPrimaryContainer, height: 1.5),
            ),
            const SizedBox(height: 12),
            if (announcement.requiresAcknowledgment)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  context.tr(
                    'Your manager needs confirmation that you read this.',
                  ),
                  style: TextStyle(color: colors.onPrimaryContainer),
                ),
              ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                onPressed: busy ? null : onRead,
                icon: const Icon(Icons.done_all),
                label: Text(
                  context.tr(
                    announcement.requiresAcknowledgment
                        ? 'Confirm I have read this'
                        : 'I have read this',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
