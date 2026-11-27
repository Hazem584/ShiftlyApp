import 'package:flutter/material.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/refresh_attendance_views.dart';
import 'package:shiftly/features/manager_experience/presentation/manager_action_links.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/presentation/cubit/work_feed_cubit.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/review_note_dialog.dart';
import 'package:shiftly/features/team_work/presentation/widgets/manager_task_card.dart';
import 'package:shiftly/features/team_work/presentation/widgets/work_feed_view.dart';

class ManagerTasksView extends StatelessWidget {
  const ManagerTasksView({
    super.key,
    required this.cubit,
    required this.workspaceId,
    required this.timezone,
    required this.onReviewed,
  });
  final WorkFeedCubit<WorkTask> cubit;
  final String workspaceId, timezone;
  final VoidCallback onReviewed;

  Future<void> _review(
    BuildContext context,
    WorkTask task,
    bool approve,
  ) async {
    final note = approve ? null : await requestReviewNote(context);
    if (!approve && note == null) return;
    final saved = await cubit.mutate(task.id, () async {
      if (task.kind == 'ATTENDANCE') {
        await getIt<AttendanceRepository>().reviewAttendance(
          workspaceId,
          task.id,
          approve
              ? AttendanceReviewDecision.approved
              : AttendanceReviewDecision.rejected,
          rejectionReason: note,
        );
      } else {
        await getIt<LeaveRequestRepository>().review(
          workspaceId,
          task.id,
          approve ? LeaveReviewDecision.approved : LeaveReviewDecision.rejected,
          rejectionReason: note,
        );
      }
    });
    if (saved && context.mounted) refreshAttendanceViews(context);
  }

  @override
  Widget build(BuildContext context) => WorkFeedView(
    cubit: cubit,
    header: const ManagerActionLinks(),
    itemBuilder: (context, task, busy) => ManagerTaskCard(
      task: task,
      workspaceId: workspaceId,
      timezone: timezone,
      busy: busy,
      onDecision: (approve) => _review(context, task, approve),
      onCorrectionReviewed: () async {
        await cubit.load();
        onReviewed();
      },
    ),
  );
}
