import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';

class AnnouncementListTile extends StatelessWidget {
  const AnnouncementListTile({
    super.key,
    required this.item,
    required this.timezone,
    required this.busy,
    required this.onTap,
  });
  final TeamAnnouncement item;
  final String timezone;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = item.acknowledgedAt != null
        ? 'Acknowledged'
        : item.requiresAcknowledgment
        ? 'Acknowledgment required'
        : item.readAt == null
        ? 'Unread'
        : 'Read';
    final timestamp = WorkspaceTime.dateTime(
      item.createdAt,
      timezone,
      locale: Localizations.localeOf(context).toString(),
    );
    return Card(
      child: ListTile(
        key: ValueKey('announcement-${item.id}'),
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          item.requiresAcknowledgment && item.acknowledgedAt == null
              ? Icons.notifications_outlined
              : Icons.article_outlined,
        ),
        title: Text(item.title),
        subtitle: Text('${item.author} · $timestamp\n${context.tr(status)}'),
        onTap: busy ? null : onTap,
      ),
    );
  }
}
