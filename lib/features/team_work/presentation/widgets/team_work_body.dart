import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/cubit/work_feed_cubit.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/correction_approval_dialog.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/review_note_dialog.dart';
import 'package:shiftly/features/team_work/presentation/widgets/announcements_view.dart';
import 'package:shiftly/features/team_work/presentation/widgets/correction_request_card.dart';
import 'package:shiftly/features/team_work/presentation/widgets/manager_tasks_view.dart';
import 'package:shiftly/features/team_work/presentation/widgets/work_feed_view.dart';

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

class TeamWorkBodyState extends State<TeamWorkBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final WorkFeedCubit<WorkTask> _tasks;
  late final WorkFeedCubit<CorrectionRequest> _corrections;
  late final WorkFeedCubit<TeamAnnouncement> _announcements;
  String? _status;
  @override
  void initState() {
    super.initState();
    final index = widget.initialTab == 'tasks' && widget.manager
        ? 0
        : widget.initialTab == 'corrections'
        ? (widget.manager ? 1 : 0)
        : (widget.manager ? 2 : 1);
    _tabs = TabController(
      length: widget.manager ? 3 : 2,
      initialIndex: index,
      vsync: this,
    );
    _tasks = WorkFeedCubit((_) => widget.repository.tasks(widget.workspaceId));
    _corrections = WorkFeedCubit(
      (page) => widget.repository.corrections(
        widget.workspaceId,
        page: page,
        status: _status,
      ),
    )..load();
    _announcements = WorkFeedCubit(
      (page) => widget.repository.announcements(widget.workspaceId, page: page),
    )..load();
    if (widget.manager) _tasks.load();
  }

  @override
  void didUpdateWidget(covariant TeamWorkBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      final index = widget.initialTab == 'tasks' && widget.manager
          ? 0
          : widget.initialTab == 'corrections'
          ? (widget.manager ? 1 : 0)
          : (widget.manager ? 2 : 1);
      _tabs.animateTo(index);
      if (widget.initialTab == 'corrections') {
        _corrections.load();
      } else if (widget.initialTab == 'announcements') {
        _announcements.load();
      } else if (widget.manager) {
        _tasks.load();
      }
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _tasks.close();
    _corrections.close();
    _announcements.close();
    super.dispose();
  }

  Future<void> _review(CorrectionRequest request, bool approve) async {
    if (approve) {
      final saved = await showDialog<bool>(
        context: context,
        builder: (_) => CorrectionApprovalDialog(
          request: request,
          repository: widget.repository,
          workspaceId: widget.workspaceId,
          timezone: widget.timezone,
        ),
      );
      if (saved == true && mounted) {
        _corrections.load();
        _tasks.load();
      }
      return;
    }
    final note = approve ? null : await requestReviewNote(context);
    if (!approve && note == null) return;
    final saved = await _corrections.mutate(
      request.id,
      () => widget.repository.reviewCorrection(
        widget.workspaceId,
        request.id,
        approve: approve,
        note: note,
      ),
    );
    if (saved) _tasks.load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      actions: [
        IconButton(
          tooltip: context.tr('Shift swaps and coverage'),
          onPressed: () => context.push('/shift-exchanges'),
          icon: const Icon(Icons.swap_horiz),
        ),
      ],
      title: Text(
        context.tr(widget.manager ? 'Team work center' : 'Team updates'),
      ),
      bottom: TabBar(
        controller: _tabs,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: [
          if (widget.manager) Tab(text: context.tr('Manager tasks')),
          Tab(text: context.tr('Attendance corrections')),
          Tab(text: context.tr('Team announcements')),
        ],
      ),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: TabBarView(
          controller: _tabs,
          children: [
            if (widget.manager)
              ManagerTasksView(
                cubit: _tasks,
                workspaceId: widget.workspaceId,
                timezone: widget.timezone,
                onReviewed: () => _corrections.load(),
              ),
            WorkFeedView(
              cubit: _corrections,
              header: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (value, label) in <(String?, String)>[
                      (null, 'All'),
                      ('PENDING', 'Pending review'),
                      ('APPROVED', 'Approved'),
                      ('REJECTED', 'Declined'),
                    ])
                      ChoiceChip(
                        label: Text(context.tr(label)),
                        selected: _status == value,
                        onSelected: (_) {
                          setState(() => _status = value);
                          _corrections.load();
                        },
                      ),
                  ],
                ),
              ),
              itemBuilder: (_, request, busy) => CorrectionRequestCard(
                request: request,
                timezone: widget.timezone,
                busy: busy,
                onApprove: widget.manager ? () => _review(request, true) : null,
                onDecline: widget.manager
                    ? () => _review(request, false)
                    : null,
              ),
            ),
            AnnouncementsView(
              repository: widget.repository,
              cubit: _announcements,
              workspaceId: widget.workspaceId,
              timezone: widget.timezone,
              manager: widget.manager,
            ),
          ],
        ),
      ),
    ),
  );
}
