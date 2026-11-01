import 'package:flutter/material.dart';
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

class TeamWorkBodyState extends State<TeamWorkBody> {
  late final WorkFeedCubit<WorkTask> _tasks;
  late final WorkFeedCubit<CorrectionRequest> _corrections;
  late final WorkFeedCubit<TeamAnnouncement> _announcements;
  String? _status;
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
      (page) => widget.repository.announcements(widget.workspaceId, page: page),
    );
    if (widget.initialTab == 'tasks' && widget.manager) _tasks.load();
    if (widget.initialTab == 'corrections') _corrections.load();
    if (widget.initialTab == 'announcements') _announcements.load();
  }

  @override
  void didUpdateWidget(covariant TeamWorkBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      if (widget.initialTab == 'tasks' && widget.manager) _tasks.load();
      if (widget.initialTab == 'corrections') _corrections.load();
      if (widget.initialTab == 'announcements') _announcements.load();
    }
  }

  @override
  void dispose() {
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
      title: Text(
        context.tr(
          widget.initialTab == 'corrections'
              ? 'Attendance corrections'
              : widget.initialTab == 'tasks' && widget.manager
              ? 'Manager tasks'
              : 'Team announcements',
        ),
      ),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: switch (widget.initialTab) {
          'tasks' when widget.manager => ManagerTasksView(
            cubit: _tasks,
            workspaceId: widget.workspaceId,
            timezone: widget.timezone,
            onReviewed: () => _tasks.load(),
          ),
          'corrections' => WorkFeedView(
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
              onDecline: widget.manager ? () => _review(request, false) : null,
            ),
          ),
          _ => AnnouncementsView(
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
