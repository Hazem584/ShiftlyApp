import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/cubit/work_feed_cubit.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/correction_review_dialog.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/review_note_dialog.dart';
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
    await cubit.mutate(task.id, () async {
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
  }

  @override
  Widget build(BuildContext context) => WorkFeedView(
    cubit: cubit,
    header: Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        context.tr('Requests first, then today’s attendance follow-up.'),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ),
    itemBuilder: (context, task, busy) {
      final (label, icon) = switch (task.kind) {
        'CORRECTION' => ('Attendance correction', Icons.edit_calendar_outlined),
        'LEAVE' => ('Leave request', Icons.event_busy_outlined),
        'ATTENDANCE' => ('Attendance review', Icons.fact_check_outlined),
        'LATE' => ('Late arrival', Icons.schedule_outlined),
        'OPEN' => ('Clock-out needs follow-up', Icons.timer_outlined),
        _ => ('Shift needs follow-up', Icons.calendar_month_outlined),
      };
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${task.name} · ${context.tr(label)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (task.startsAt != null)
                Text(
                  '${WorkspaceTime.dateTime(task.startsAt!, timezone, locale: Localizations.localeOf(context).toString())}\n${WorkspaceTime.dateTime(task.endsAt!, timezone, locale: Localizations.localeOf(context).toString())}',
                ),
              Text(
                WorkspaceTime.dateTime(
                  task.createdAt,
                  timezone,
                  locale: Localizations.localeOf(context).toString(),
                ),
              ),
              if (task.detail?.isNotEmpty == true) Text(task.detail!),
              if (task.minutesLate != null)
                Text(
                  context.tr('Late by {minutes} minutes', {
                    'minutes': task.minutesLate.toString(),
                  }),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (task.kind == 'CORRECTION')
                    FilledButton(
                      onPressed: () async {
                        final saved = await showDialog<bool>(
                          context: context,
                          builder: (_) => CorrectionReviewDialog(
                            repository: getIt<TeamWorkRepository>(),
                            workspaceId: workspaceId,
                            requestId: task.id,
                            timezone: timezone,
                          ),
                        );
                        if (saved == true) {
                          await cubit.load();
                          onReviewed();
                        }
                      },
                      child: Text(context.tr('Review correction')),
                    )
                  else if (task.needsDecision) ...[
                    FilledButton(
                      onPressed: busy
                          ? null
                          : () => _review(context, task, true),
                      child: Text(context.tr('Approve')),
                    ),
                    OutlinedButton(
                      onPressed: busy
                          ? null
                          : () => _review(context, task, false),
                      child: Text(context.tr('Decline')),
                    ),
                  ] else
                    OutlinedButton(
                      onPressed: () => context.push(
                        task.kind == 'SHIFT'
                            ? '/dashboard/shifts'
                            : '/attendance',
                      ),
                      child: Text(context.tr('View attendance and shifts')),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
