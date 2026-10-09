import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
            const Text('Clock-in outcome needs confirmation'),
            Text('Saved request ID: ${state.recovery!.clientAttendanceId}'),
            Text(
              'Saved ${state.recovery!.occurrenceKind ?? 'unknown'} occurrence on '
              '${state.recovery!.operationalDate ?? 'unknown date'}. A new shift is blocked until recovery finishes.',
            ),
            FilledButton(
              onPressed: state.submittingTemplateId != null
                  ? null
                  : () => context
                        .read<FlexibleAttendanceCubit>()
                        .recoverClockIn(),
              child: const Text('Recover saved clock-in'),
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
                        ? 'Legacy shift attendance is active'
                        : 'Active attendance is unavailable',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    current.source == AttendanceSource.legacyShift
                        ? 'Open My Shifts, then Legacy shift history / active clock-out to finish this attendance.'
                        : 'Refresh before taking another attendance action.',
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
                  'Clock in to a fixed shift',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Refresh eligibility',
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Ask your manager to assign your baseline fixed shift. Explicitly authorized extras remain optional.',
              ),
            ),
          if (state.eligibility?.openAttendanceId != null)
            const Text(
              'Attendance is already open. Refresh to restore it before another action.',
            ),
          if (current != null && !current.isOpen)
            Text(
              'Attendance ${current.occurrenceKind ?? 'historical'} on '
              '${current.operationalDate ?? 'unrecorded date'} is used and cannot be reopened.',
            ),
          if (entries.isEmpty) ...[
            const SizedBox(height: 10),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.event_busy_outlined, color: AppColors.textSecondary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No template is eligible at this time. Your manager may need to add a work pattern, or the check-in window may not be open.',
                  ),
                ),
              ],
            ),
            if (state.templates.isNotEmpty &&
                state.eligibility?.status == 'ASSIGNED') ...[
              const SizedBox(height: 12),
              Text(
                'Assigned shift schedule',
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
        title: Text('Clock in to ${entry.template.name}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${WorkspaceTime.time(entry.scheduledStartAt, timezone, locale: Localizations.localeOf(context).toString())} – ${WorkspaceTime.time(entry.scheduledEndAt, timezone, locale: Localizations.localeOf(context).toString())}',
            ),
            Text('Operational date: ${entry.operationalDate}'),
            Text(
              'Classification: ${attendanceClassificationLabel(entry.classification)}${entry.lateMinutes > 0 ? ' • ${entry.lateMinutes} min late' : ''}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-flexible-clock-in'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clock in'),
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
        title: const Text('Clock out now?'),
        content: const Text(
          'Your final worked duration will be calculated by the server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Stay clocked in'),
          ),
          FilledButton(
            key: const Key('confirm-flexible-clock-out'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clock out'),
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
