import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/failure_notice.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/active_attendance_card.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/attendance_presentation.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/attendance_status_card.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/eligibility_tile.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/legacy_clock_in_review_card.dart';

class FlexibleAttendancePanel extends StatelessWidget {
  const FlexibleAttendancePanel({required this.timezone, super.key});
  final String timezone;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<FlexibleAttendanceCubit, FlexibleAttendanceState>(
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!state.loading) ...[
              AttendanceStatusCard(state: state, timezone: timezone),
              const SizedBox(height: 12),
            ],
            if (state.failure != null) ...[
              FailureNotice(
                failure: state.failure!,
                refreshing: state.refreshing,
                onRefresh:
                    state.clockingOut || state.submittingTemplateId != null
                    ? null
                    : () => context.read<FlexibleAttendanceCubit>().load(
                        refresh: true,
                      ),
              ),
              const SizedBox(height: 12),
            ],
            _content(context, state),
          ],
        ),
      );

  Widget _content(BuildContext context, FlexibleAttendanceState state) {
    if (state.loading) {
      return const SurfaceCard(
        child: SizedBox(
          height: 116,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (state.recovery != null) {
      return SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.tr('Clock-in outcome needs confirmation')),
            Text(
              context.tr('Saved request ID: {value1}', {
                'value1': (state.recovery!.clientAttendanceId).toString(),
              }),
            ),
            Text(
              context.tr(
                'Saved {value1} occurrence on {value2}. A new shift is blocked until recovery finishes.',
                {
                  'value1': (state.recovery!.occurrenceKind ?? 'unknown')
                      .toString(),
                  'value2': (state.recovery!.operationalDate ?? 'unknown date')
                      .toString(),
                },
              ),
            ),
            FilledButton(
              onPressed: state.submittingTemplateId != null
                  ? null
                  : () => context
                        .read<FlexibleAttendanceCubit>()
                        .recoverClockIn(),
              child: Text(context.tr('Recover saved clock-in')),
            ),
          ],
        ),
      );
    }
    final current = state.current;
    final legacyReview = LegacyClockInReviewCard(
      reviews: state.legacyReviews,
      onRefresh:
          state.refreshing ||
              state.clockingOut ||
              state.submittingTemplateId != null
          ? null
          : () => context.read<FlexibleAttendanceCubit>().load(refresh: true),
    );
    if (current != null && current.isOpen && current.isActionable) {
      final activeCard = ActiveAttendanceCard(
        attendance: current,
        timezone: timezone,
        busy: state.clockingOut,
        onClockOut: () => _clockOut(context),
      );
      return state.legacyReviews.isEmpty
          ? activeCard
          : Column(
              children: [activeCard, const SizedBox(height: 10), legacyReview],
            );
    }
    if (current != null && current.isOpen) {
      return SurfaceCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              current.source == AttendanceSource.legacyShift
                  ? Icons.event_available_outlined
                  : Icons.help_outline_rounded,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    current.source == AttendanceSource.legacyShift
                        ? context.tr('Legacy shift attendance is active')
                        : context.tr('Active attendance is unavailable'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    current.source == AttendanceSource.legacyShift
                        ? context.tr(
                            'Open My Shifts, then Legacy shift history / active clock-out to finish this attendance.',
                          )
                        : context.tr(
                            'Refresh before taking another attendance action.',
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    if (state.legacyReviewRequired) {
      return legacyReview;
    }
    final entries = state.eligibility?.authorizedOccurrences ?? const [];
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.legacyReviews.isNotEmpty) legacyReview,
          Row(
            children: [
              const Icon(Icons.bolt_rounded),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('Clock in to a fixed shift'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: context.tr('Refresh eligibility'),
                onPressed: state.refreshing
                    ? null
                    : () => context.read<FlexibleAttendanceCubit>().load(
                        refresh: true,
                      ),
                icon: state.refreshing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          if (state.eligibility?.status == 'SHIFT_ASSIGNMENT_REQUIRED')
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                context.tr(
                  'Ask your manager to assign your baseline fixed shift. Explicitly authorized extras remain optional.',
                ),
              ),
            ),
          if (state.eligibility?.openAttendanceId != null)
            Text(
              context.tr(
                'Attendance is already open. Refresh to restore it before another action.',
              ),
            ),
          if (current != null && !current.isOpen)
            Text(
              context.tr(
                'Attendance {value1} on {value2} is used and cannot be reopened.',
                {
                  'value1': (current.occurrenceKind ?? 'historical').toString(),
                  'value2': (current.operationalDate ?? 'unrecorded date')
                      .toString(),
                },
              ),
            ),
          if (entries.isEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.event_busy_outlined,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr(
                      'No template is eligible at this time. Your manager may need to add a work pattern, or the check-in window may not be open.',
                    ),
                  ),
                ),
              ],
            ),
            if (state.templates.isNotEmpty &&
                state.eligibility?.status == 'ASSIGNED') ...[
              const SizedBox(height: 12),
              Text(
                context.tr('Assigned shift schedule'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final template in state.templates)
                    Chip(
                      avatar: CircleAvatar(
                        backgroundColor: attendanceTemplateColor(
                          template.color,
                        ),
                      ),
                      label: Text(
                        template.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
          ] else ...[
            const SizedBox(height: 10),
            for (final entry in entries) ...[
              EligibilityTile(
                entry: entry,
                timezone: timezone,
                busy: state.submittingTemplateId != null,
                onTap:
                    entry.canClockIn &&
                        !state.recoveryBlocked &&
                        !state.refreshing &&
                        state.failure == null &&
                        state.eligibility?.openAttendanceId == null
                    ? () => _clockIn(context, entry)
                    : null,
              ),
              if (entry != entries.last) const SizedBox(height: 9),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _clockIn(
    BuildContext context,
    EligibleShiftOccurrence entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          context.tr('Clock in to {value1}?', {
            'value1': (entry.template.name).toString(),
          }),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('{value1} – {value2}', {
                'value1': (WorkspaceTime.time(
                  entry.scheduledStartAt,
                  timezone,
                  locale: Localizations.localeOf(context).toString(),
                )).toString(),
                'value2': (WorkspaceTime.time(
                  entry.scheduledEndAt,
                  timezone,
                  locale: Localizations.localeOf(context).toString(),
                )).toString(),
              }),
            ),
            Text(
              context.tr('Operational date: {value1}', {
                'value1': (entry.operationalDate).toString(),
              }),
            ),
            Text(
              context.tr('Classification: {value1}{value2}', {
                'value1': (attendanceClassificationLabel(entry.classification))
                    .toString(),
                'value2':
                    (entry.lateMinutes > 0
                            ? ' • ${entry.lateMinutes} min late'
                            : '')
                        .toString(),
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            key: const Key('confirm-flexible-clock-in'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('Clock in')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final result = await context.read<FlexibleAttendanceCubit>().clockIn(entry);
    if (context.mounted && result == FixedShiftMutationResult.success) {
      ToastService.success(context, message: 'Clock-in confirmed.');
    }
  }

  Future<void> _clockOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Clock out now?')),
        content: Text(
          context.tr(
            'Your final worked duration will be calculated by the server.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('Stay clocked in')),
          ),
          FilledButton(
            key: const Key('confirm-flexible-clock-out'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('Clock out')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final result = await context.read<FlexibleAttendanceCubit>().clockOut();
    if (context.mounted && result == FixedShiftMutationResult.success) {
      ToastService.success(context, message: 'Clock-out confirmed.');
    }
  }
}
