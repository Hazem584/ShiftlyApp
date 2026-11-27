import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/presentation/cubit/work_feed_cubit.dart';
import 'package:shiftly/features/team_work/presentation/widgets/announcement_list_tile.dart';

class AnnouncementsFeedList extends StatelessWidget {
  const AnnouncementsFeedList({
    super.key,
    required this.state,
    required this.items,
    required this.archive,
    required this.unread,
    required this.timezone,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onFilterArchive,
    required this.onToggleUnread,
    required this.onOpenItem,
  });
  final WorkFeedState<TeamAnnouncement> state;
  final List<TeamAnnouncement> items;
  final bool archive, unread;
  final String timezone;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final ValueChanged<bool> onFilterArchive, onToggleUnread;
  final ValueChanged<TeamAnnouncement> onOpenItem;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    child: ListView(
      padding: const EdgeInsets.all(24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              key: const Key('announcements-pending'),
              label: Text(context.tr('Pending updates')),
              selected: !archive,
              onSelected: (_) => onFilterArchive(false),
            ),
            ChoiceChip(
              key: const Key('announcements-archive'),
              label: Text(context.tr('Archive')),
              selected: archive,
              onSelected: (_) => onFilterArchive(true),
            ),
            if (archive)
              FilterChip(
                label: Text(context.tr('Unread')),
                selected: unread,
                onSelected: onToggleUnread,
              ),
          ],
        ),
        const SizedBox(height: 24),
        if (state.loading) const AppContentLoading(rows: 1),
        if (state.error != null) ...[
          Text(context.tr(state.error!)),
          TextButton(onPressed: onRefresh, child: Text(context.tr('Retry'))),
        ],
        if (!state.loading && items.isEmpty && state.error == null)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              context.tr(
                archive ? 'No updates here yet.' : 'No pending updates.',
              ),
            ),
          ),
        for (final item in items) ...[
          AnnouncementListTile(
            item: item,
            timezone: timezone,
            busy: state.busyId != null,
            onTap: () => onOpenItem(item),
          ),
          const SizedBox(height: 14),
        ],
        if (state.hasMore)
          TextButton(
            onPressed: state.loadingMore ? null : onLoadMore,
            child: Text(context.tr('Load more')),
          ),
        const SizedBox(height: 12),
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              context.tr(
                'Open an update to read it. Acknowledgment is a separate action.',
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
