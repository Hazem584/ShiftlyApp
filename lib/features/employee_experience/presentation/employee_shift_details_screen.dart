import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/work_duration.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/confirm_action.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/eligible_shift_occurrence.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/missed_attendance_request_dialog.dart';

import 'employee_active_attendance_screen.dart';
import 'employee_page.dart';
import 'employee_tile.dart';

class EmployeeShiftDetailsScreen extends StatelessWidget {
  const EmployeeShiftDetailsScreen({
    required this.entry,
    required this.timezone,
    super.key,
  });
  final EligibleShiftOccurrence entry;
  final String timezone;
  Future<void> _checkIn(
    BuildContext context,
    EligibleShiftOccurrence value,
  ) async {
    final cubit = context.read<FlexibleAttendanceCubit>();
    final confirmed = await confirmAction(
      context,
      title: 'Start your shift?',
      message: '${value.template.name} · ${value.operationalDate} · $timezone',
      action: 'Confirm check-in',
      actionKey: 'confirm-flexible-clock-in',
    );
    if (!confirmed || !context.mounted) return;
    final result = await cubit.clockIn(value);
    if (context.mounted && result == FixedShiftMutationResult.success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => EmployeeActiveAttendanceScreen(timezone: timezone),
        ),
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<FlexibleAttendanceCubit, FlexibleAttendanceState>(
    builder: (context, state) {
      final live = state.eligibility?.authorizedOccurrences
          .where((e) => e.identity == entry.identity)
          .firstOrNull;
      final e = live ?? entry;
      final hasOpen =
          state.current?.isOpen == true ||
          state.eligibility?.openAttendanceId != null;
      final safe =
          live != null &&
          !state.loading &&
          !state.refreshing &&
          !state.recoveryBlocked &&
          state.recovery == null &&
          !state.legacyReviewRequired &&
          state.failure == null &&
          state.submittingTemplateId == null &&
          !state.clockingOut &&
          !hasOpen;
      final evaluated = state.eligibility?.evaluatedAt;
      final upcoming =
          evaluated != null && e.checkInWindowStart.isAfter(evaluated);
      final missing =
          evaluated != null &&
          !e.scheduledEndAt.isAfter(evaluated) &&
          !e.alreadyUsed;
      final canReview =
          safe &&
          missing &&
          !e.pendingReview &&
          getIt.isRegistered<TeamWorkRepository>() &&
          ((e.occurrenceKind == 'BASELINE' && e.assignmentId != null) ||
              (e.occurrenceKind == 'EXTRA' && e.extraAuthorizationId != null));
      String time(DateTime d) => WorkspaceTime.time(
        d,
        timezone,
        locale: Localizations.localeOf(context).toString(),
      );
      final status = hasOpen
          ? 'You have an open attendance'
          : e.alreadyUsed
          ? 'This shift is already recorded'
          : e.pendingReview
          ? 'Your request is waiting for your manager’s review.'
          : upcoming
          ? 'Check-in not open yet'
          : evaluated != null && e.checkInWindowEnd.isBefore(evaluated)
          ? 'The check-in window has closed.'
          : !e.canClockIn
          ? 'No check-in available right now'
          : null;
      return EmployeePage(
        title: 'Shift details',
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (safe && e.canClockIn)
              FilledButton(
                key: Key('eligible-template-${e.template.id}'),
                onPressed: () => _checkIn(context, e),
                child: Text(context.tr('Check in')),
              ),
            if (canReview)
              FilledButton(
                key: Key('review-missed-${e.identity}'),
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (_) => MissedAttendanceRequestDialog(
                      entry: e,
                      workspaceId: state.eligibility!.workspaceId,
                      timezone: timezone,
                      repository: getIt<TeamWorkRepository>(),
                    ),
                  );
                  if (result == true && context.mounted) {
                    await context.read<FlexibleAttendanceCubit>().load(
                      refresh: true,
                    );
                    if (context.mounted) {
                      context.push('/team-work?tab=corrections');
                    }
                  }
                },
                child: Text(context.tr('Request attendance review')),
              ),
            if (hasOpen)
              FilledButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        EmployeeActiveAttendanceScreen(timezone: timezone),
                  ),
                ),
                child: Text(context.tr('View attendance')),
              ),
            if (e.alreadyUsed)
              OutlinedButton(
                onPressed: () => context.go('/employee?tab=history'),
                child: Text(context.tr('View attendance history')),
              ),
            if (e.pendingReview)
              TextButton(
                onPressed: () => context.push('/team-work?tab=corrections'),
                child: Text(context.tr('View my requests')),
              ),
          ],
        ),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              '${e.operationalDate} · $timezone',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            EmployeeTile(
              title: e.template.name,
              subtitle:
                  '${time(e.scheduledStartAt)}–${time(e.scheduledEndAt)} · ${context.tr(e.scheduleExceptionId != null
                      ? 'Date-specific change'
                      : e.occurrenceKind == 'EXTRA'
                      ? 'Authorized extra'
                      : 'Baseline assignment')}',
              icon: Icons.calendar_today_outlined,
            ),
            const SizedBox(height: 14),
            EmployeeTile(
              title: context.tr('Check-in opens at {time}', {
                'time': time(e.checkInWindowStart),
              }),
              subtitle: context.tr(
                'Latest check-in {time} · {minutes} min grace',
                {
                  'time': time(e.checkInWindowEnd),
                  'minutes': '${e.template.graceMinutes}',
                },
              ),
            ),
            const SizedBox(height: 14),
            EmployeeTile(
              title: context.tr('Minimum work · {time}', {
                'time': workDuration(
                  e.template.minimumWorkMinutes,
                  arabic: Localizations.localeOf(context).languageCode == 'ar',
                ),
              }),
              subtitle: context.tr('End of shift · {time}', {
                'time': time(e.scheduledEndAt),
              }),
              icon: Icons.timelapse_outlined,
            ),
            if (e.scheduleExceptionReason != null) ...[
              const SizedBox(height: 16),
              Text(e.scheduleExceptionReason!),
            ],
            if (status != null) ...[
              const SizedBox(height: 24),
              Text(
                context.tr(status),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
            if (state.failure != null) ...[
              const SizedBox(height: 12),
              Text(
                state.failure!.message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              TextButton(
                onPressed: state.refreshing
                    ? null
                    : () => context.read<FlexibleAttendanceCubit>().load(
                        refresh: true,
                      ),
                child: Text(context.tr('Refresh')),
              ),
            ],
          ],
        ),
      );
    },
  );
}
