import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/cubit/work_feed_cubit.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/announcement_readers_dialog.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/publish_announcement_dialog.dart';
import 'package:shiftly/features/team_work/presentation/widgets/work_feed_view.dart';

class AnnouncementsView extends StatelessWidget {
  const AnnouncementsView({
    super.key,
    required this.repository,
    required this.cubit,
    required this.workspaceId,
    required this.timezone,
    required this.manager,
  });
  final TeamWorkRepository repository;
  final WorkFeedCubit<TeamAnnouncement> cubit;
  final String workspaceId, timezone;
  final bool manager;
  Future<void> _open(BuildContext context, TeamAnnouncement item) async {
    // Mark read only after explicitly opening the full announcement.
    if (item.readAt == null) {
      await cubit.mutate(
        item.id,
        () => repository.markAnnouncement(workspaceId, item.id),
      );
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(child: SelectableText(item.body)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('Close')),
          ),
        ],
      ),
    );
  }

  Future<void> _readers(BuildContext context, TeamAnnouncement item) =>
      showDialog<void>(
        context: context,
        builder: (_) => AnnouncementReadersDialog(
          repository: repository,
          workspaceId: workspaceId,
          announcementId: item.id,
          timezone: timezone,
        ),
      );

  Future<void> _acknowledge(BuildContext context, TeamAnnouncement item) async {
    if (!manager) {
      await cubit.mutate(
        item.id,
        () => repository.markAnnouncement(
          workspaceId,
          item.id,
          acknowledge: true,
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Acknowledge this update?')),
        content: Text(item.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            key: const Key('confirm-announcement-acknowledgment'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('Acknowledge')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted || cubit.isClosed) return;
    await cubit.mutate(
      item.id,
      () =>
          repository.markAnnouncement(workspaceId, item.id, acknowledge: true),
    );
  }

  @override
  Widget build(BuildContext context) => WorkFeedView(
    cubit: cubit,
    header: manager
        ? Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.icon(
                icon: const Icon(Icons.campaign_outlined),
                label: Text(context.tr('Publish team announcement')),
                onPressed: () async {
                  final published = await showDialog<bool>(
                    context: context,
                    builder: (_) => PublishAnnouncementDialog(
                      repository: repository,
                      workspaceId: workspaceId,
                      isCurrent: () => context.mounted && !cubit.isClosed,
                    ),
                  );
                  if (published == true) await cubit.load();
                },
              ),
            ),
          )
        : null,
    itemBuilder: (context, item, busy) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: Theme.of(context).textTheme.titleMedium),
            Text(
              '${item.author} · ${WorkspaceTime.dateTime(item.createdAt, timezone, locale: Localizations.localeOf(context).toString())}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(item.body, maxLines: 3, overflow: TextOverflow.ellipsis),
            if (item.requiresAcknowledgment)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  context.tr(
                    item.acknowledgedAt != null
                        ? 'Acknowledged'
                        : 'Acknowledgment required',
                  ),
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: busy ? null : () => _open(context, item),
                  child: Text(context.tr('Read announcement')),
                ),
                if (manager)
                  TextButton(
                    onPressed: () => _readers(context, item),
                    child: Text(context.tr('View readers')),
                  ),
                if (item.requiresAcknowledgment &&
                    item.acknowledgedAt == null &&
                    item.readAt != null)
                  FilledButton.icon(
                    onPressed: busy ? null : () => _acknowledge(context, item),
                    icon: const Icon(Icons.check),
                    label: Text(context.tr('I have read and understood')),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
