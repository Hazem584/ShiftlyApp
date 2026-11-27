import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';

Widget buildAnnouncementDetailContent(
  BuildContext context, {
  required TeamAnnouncement item,
  required String timezone,
  required bool read,
  required bool acknowledged,
  required bool busy,
  required String? error,
  required VoidCallback onRetry,
}) => ListView(
  padding: const EdgeInsets.all(24),
  children: [
    Text(
      '${item.author} · ${WorkspaceTime.dateTime(item.createdAt, timezone, locale: Localizations.localeOf(context).toString())}',
      style: Theme.of(context).textTheme.bodySmall,
    ),
    const SizedBox(height: 24),
    Text(item.title, style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 16),
    SelectableText(item.body, style: Theme.of(context).textTheme.bodyLarge),
    const SizedBox(height: 28),
    if (item.requiresAcknowledgment)
      Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(
                  acknowledged
                      ? 'Acknowledgment saved.'
                      : 'Acknowledgment required',
                ),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                context.tr(
                  acknowledged
                      ? 'Your manager can now see that you acknowledged the announcement.'
                      : 'Reading this update does not confirm acknowledgment.',
                ),
              ),
            ],
          ),
        ),
      ),
    if (read && !acknowledged)
      Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Text(
          context.tr(
            item.requiresAcknowledgment
                ? 'Read · Still needs your acknowledgment.'
                : 'Read',
          ),
        ),
      ),
    if (error != null) ...[
      const SizedBox(height: 16),
      Text(
        context.tr(error),
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      TextButton(
        onPressed: busy ? null : onRetry,
        child: Text(context.tr('Retry')),
      ),
    ],
  ],
);
