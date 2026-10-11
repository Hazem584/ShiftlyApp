import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/cubit/work_feed_cubit.dart';
import 'package:shiftly/features/team_work/presentation/widgets/pending_announcement_card.dart';

class PendingAnnouncements extends StatefulWidget {
  const PendingAnnouncements({
    super.key,
    required this.repository,
    required this.workspaceId,
    required this.timezone,
    this.refreshToken,
  });
  final TeamWorkRepository repository;
  final String workspaceId, timezone;
  final Object? refreshToken;

  @override
  State<PendingAnnouncements> createState() => _PendingAnnouncementsState();
}

class _PendingAnnouncementsState extends State<PendingAnnouncements>
    with WidgetsBindingObserver {
  late WorkFeedCubit<TeamAnnouncement> _feed;
  final _dismissed = <String>{};

  void _bind() {
    _dismissed.clear();
    final repository = widget.repository;
    final workspaceId = widget.workspaceId;
    _feed = WorkFeedCubit(
      (page) =>
          repository.announcements(workspaceId, page: page, pendingOnly: true),
    )..load();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bind();
  }

  @override
  void didUpdateWidget(covariant PendingAnnouncements oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspaceId != widget.workspaceId ||
        oldWidget.repository != widget.repository) {
      _feed.close();
      _bind();
    } else if (oldWidget.refreshToken != widget.refreshToken) {
      _feed.load();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _feed.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _feed.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<
        WorkFeedCubit<TeamAnnouncement>,
        WorkFeedState<TeamAnnouncement>
      >(
        bloc: _feed,
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.loading && state.items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(),
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
                      onPressed: state.loading ? null : () => _feed.load(),
                      child: Text(context.tr('Try again')),
                    ),
                  ],
                ),
              ),
            for (final item in state.items)
              if (!_dismissed.contains(item.id))
                PendingAnnouncementCard(
                  announcement: item,
                  timezone: widget.timezone,
                  busy: state.busyId != null || state.loading,
                  onRead: () => _feed.mutate(item.id, () async {
                    await widget.repository.markAnnouncement(
                      widget.workspaceId,
                      item.id,
                      acknowledge: item.requiresAcknowledgment,
                    );
                    _dismissed.add(item.id);
                  }),
                ),
            if (state.hasMore)
              TextButton(
                onPressed:
                    state.loadingMore || state.loading || state.busyId != null
                    ? null
                    : () => _feed.load(more: true),
                child: Text(context.tr('More announcements')),
              ),
          ],
        ),
      );
}
