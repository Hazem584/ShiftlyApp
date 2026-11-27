import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/routing/app_routes.dart';
import 'package:shiftly/core/routing/open_app_route.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/correction_review_dialog.dart';

(String, IconData) managerTaskMeta(String kind) => switch (kind) {
  'CORRECTION' => ('Attendance correction', Icons.edit_calendar_outlined),
  'LEAVE' => ('Leave request', Icons.event_busy_outlined),
  'ATTENDANCE' => ('Attendance review', Icons.fact_check_outlined),
  'LATE' => ('Late arrival', Icons.schedule_outlined),
  'OPEN' => ('Clock-out needs follow-up', Icons.timer_outlined),
  _ => ('Shift needs follow-up', Icons.calendar_month_outlined),
};

class ManagerTaskCard extends StatelessWidget {
  const ManagerTaskCard({
    super.key,
    required this.task,
    required this.workspaceId,
    required this.timezone,
    required this.busy,
    required this.onDecision,
    required this.onCorrectionReviewed,
  });
  final WorkTask task;
  final String workspaceId, timezone;
  final bool busy;
  final ValueChanged<bool> onDecision;
  final Future<void> Function() onCorrectionReviewed;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = managerTaskMeta(task.kind);
    final locale = Localizations.localeOf(context).toString();
    String fmt(DateTime d) => WorkspaceTime.dateTime(d, timezone, locale: locale);
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
              Text('${fmt(task.startsAt!)}\n${fmt(task.endsAt!)}'),
            Text(fmt(task.createdAt)),
            if (task.detail?.isNotEmpty == true) Text(task.detail!),
            if (task.minutesLate != null)
              Text(
                context.tr('Late by {minutes} minutes', {
                  'minutes': '${task.minutesLate}',
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
                      if (saved == true) await onCorrectionReviewed();
                    },
                    child: Text(context.tr('Review correction')),
                  )
                else if (task.needsDecision) ...[
                  FilledButton(
                    onPressed: busy ? null : () => onDecision(true),
                    child: Text(context.tr('Approve')),
                  ),
                  OutlinedButton(
                    onPressed: busy ? null : () => onDecision(false),
                    child: Text(context.tr('Decline')),
                  ),
                ] else
                  OutlinedButton(
                    onPressed: () => openAppRoute(
                      GoRouter.of(context),
                      task.kind == 'SHIFT'
                          ? AppRoutes.managerShifts
                          : AppRoutes.attendance,
                    ),
                    child: Text(context.tr('View attendance and shifts')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
