import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/cubit/work_feed_cubit.dart';
import 'package:shiftly/features/team_work/presentation/widgets/announcements_view.dart';
import 'package:shiftly/features/team_work/presentation/widgets/manager_tasks_view.dart';
import 'package:shiftly/features/team_work/presentation/widgets/team_work_corrections_tab.dart';

class TeamWorkBody extends StatefulWidget {
  const TeamWorkBody({
    super.key,
    required this.workspaceId,
    required this.timezone,
    required this.manager,
    required this.initialTab,
    required this.repository,
  });
  final String workspaceId, timezone, initialTab;
  final bool manager;
  final TeamWorkRepository repository;
  @override
  State<TeamWorkBody> createState() => TeamWorkBodyState();
}

class TeamWorkBodyState extends State<TeamWorkBody> {
  late final WorkFeedCubit<WorkTask> _tasks;
  late final WorkFeedCubit<CorrectionRequest> _corrections;
  late final WorkFeedCubit<TeamAnnouncement> _announcements;
  String? _status;
  late bool _pendingAnnouncements = !widget.manager;

  void _loadActiveTab() {
    if (widget.initialTab == 'tasks' && widget.manager) _tasks.load();
    if (widget.initialTab == 'corrections') _corrections.load();
    if (widget.initialTab == 'announcements') _announcements.load();
  }

  @override
  void initState() {
    super.initState();
    _tasks = WorkFeedCubit((_) => widget.repository.tasks(widget.workspaceId));
    _corrections = WorkFeedCubit(
      (page) => widget.repository.corrections(
        widget.workspaceId,
        page: page,
        status: _status,
      ),
    );
    _announcements = WorkFeedCubit(
      (page) => widget.repository.announcements(
        widget.workspaceId,
        page: page,
        pendingOnly: _pendingAnnouncements,
      ),
    );
    _loadActiveTab();
  }

  @override
  void didUpdateWidget(covariant TeamWorkBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) _loadActiveTab();
  }

  @override
  void dispose() {
    _tasks.close();
    _corrections.close();
    _announcements.close();
    super.dispose();
  }

  String _title() => widget.initialTab == 'corrections'
      ? (widget.manager ? 'Attendance corrections' : 'My corrections')
      : widget.initialTab == 'tasks' && widget.manager
      ? 'Action inbox'
      : 'Team announcements';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr(_title()))),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: switch (widget.initialTab) {
          'tasks' when widget.manager => ManagerTasksView(
            cubit: _tasks,
            workspaceId: widget.workspaceId,
            timezone: widget.timezone,
            onReviewed: _tasks.load,
          ),
          'corrections' => TeamWorkCorrectionsTab(
            cubit: _corrections,
            status: _status,
            timezone: widget.timezone,
            manager: widget.manager,
            onStatusChanged: (value) {
              setState(() => _status = value);
              _corrections.load();
            },
            onReview: (req, approve) => reviewTeamWorkCorrection(
              context: context,
              isMounted: () => mounted,
              request: req,
              approve: approve,
              repository: widget.repository,
              workspaceId: widget.workspaceId,
              timezone: widget.timezone,
              corrections: _corrections,
              tasks: _tasks,
            ),
          ),
          _ => AnnouncementsView(
            onPendingChanged: (pending) {
              _pendingAnnouncements = pending;
              _announcements.load();
            },
            repository: widget.repository,
            cubit: _announcements,
            workspaceId: widget.workspaceId,
            timezone: widget.timezone,
            manager: widget.manager,
          ),
        },
      ),
    ),
  );
}
