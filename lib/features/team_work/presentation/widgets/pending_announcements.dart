import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/cubit/work_feed_cubit.dart';
import 'package:shiftly/features/team_work/presentation/widgets/pending_announcements_list.dart';

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

  void _bind() {
    _feed = WorkFeedCubit(
      (page) => widget.repository.announcements(
        widget.workspaceId,
        page: page,
        pendingOnly: true,
      ),
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
        builder: (context, state) => PendingAnnouncementsList(
          state: state,
          repository: widget.repository,
          workspaceId: widget.workspaceId,
          timezone: widget.timezone,
          onReload: () async {
            if (!_feed.isClosed) await _feed.load();
          },
          onLoadMore: () => _feed.load(more: true),
        ),
      );
}
