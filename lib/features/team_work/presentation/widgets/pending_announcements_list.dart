import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/dashboard_card_loading.dart';
import 'package:shiftly/features/communication/presentation/announcement_detail_screen.dart';
import 'package:shiftly/features/communication/presentation/communication_actions.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/cubit/work_feed_cubit.dart';
import 'package:shiftly/features/team_work/presentation/widgets/pending_announcement_card.dart';

class PendingAnnouncementsList extends StatelessWidget {
  const PendingAnnouncementsList({
    super.key,
    required this.state,
    required this.repository,
    required this.workspaceId,
    required this.timezone,
    required this.onReload,
    required this.onLoadMore,
  });
  final WorkFeedState<TeamAnnouncement> state;
  final TeamWorkRepository repository;
  final String workspaceId, timezone;
  final Future<void> Function() onReload;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (state.loading && state.items.isEmpty)
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: DashboardCardLoading(kind: DashboardCardKind.announcement),
        ),
      if (state.error != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('Could not update team announcements.'),
                ),
              ),
              TextButton(
                onPressed: state.loading ? null : onReload,
                child: Text(context.tr('Try again')),
              ),
            ],
          ),
        ),
      for (final item in state.items)
        PendingAnnouncementCard(
          announcement: item,
          timezone: timezone,
          busy: state.busyId != null || state.loading,
          onRead: () => openCommunicationPage(
            context,
            AnnouncementDetailScreen(
              item: item,
              repository: repository,
              workspaceId: workspaceId,
              timezone: timezone,
              onChanged: onReload,
            ),
          ),
        ),
      if (state.hasMore)
        TextButton(
          onPressed: state.loadingMore || state.loading || state.busyId != null
              ? null
              : onLoadMore,
          child: Text(context.tr('More announcements')),
        ),
    ],
  );
}
