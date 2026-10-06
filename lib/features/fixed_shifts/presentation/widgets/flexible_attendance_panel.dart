import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/fixed_shifts/data/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';

class FlexibleAttendancePanel extends StatelessWidget {
  const FlexibleAttendancePanel({required this.timezone, super.key});
  final String timezone;

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<FlexibleAttendanceCubit, FlexibleAttendanceState>(
    listenWhen: (a, b) => a.failure != b.failure && b.failure != null,
    listener: (context, state) => ToastService.error(
      context,
      message: state.failure!.requestId == null
          ? state.failure!.message
          : '${state.failure!.message} Support reference: ${state.failure!.requestId}',
    ),
    builder: (context, state) {
      if (state.loading) {
        return const SurfaceCard(
          child: SizedBox(
            height: 116,
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }
      final current = state.current;
      if (current != null && current.isOpen && current.isActionable) {
        return _ActiveAttendanceCard(
          attendance: current,
          timezone: timezone,
          busy: state.clockingOut,
          onClockOut: () => _clockOut(context),
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
                          ? 'Use the existing Shifts screen to manage this scheduled shift.'
                          : 'Refresh before taking another attendance action.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
      final entries = state.eligibility?.eligibleTemplates ?? const [];
      return SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            if (state.failure != null) ...[
              const SizedBox(height: 6),
              Text(
                state.failure!.message,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
            if (entries.isEmpty) ...[
              const SizedBox(height: 10),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.event_busy_outlined,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No template is eligible at this time. Your manager may need to add a work pattern, or the check-in window may not be open.',
                    ),
                  ),
                ],
              ),
              if (state.templates.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Available templates',
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
                          backgroundColor: _color(template.color),
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
                _EligibilityTile(
                  entry: entry,
                  timezone: timezone,
                  busy: state.submittingTemplateId != null,
                  onTap: entry.canClockIn
                      ? () => _clockIn(context, entry)
                      : null,
                ),
                if (entry != entries.last) const SizedBox(height: 9),
              ],
            ],
          ],
        ),
      );
    },
  );

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
              '${WorkspaceTime.time(entry.scheduledStartAt, timezone)} – ${WorkspaceTime.time(entry.scheduledEndAt, timezone)}',
            ),
            Text('Operational date: ${entry.operationalDate}'),
            Text(
              'Classification: ${_classification(entry.classification)}${entry.lateMinutes > 0 ? ' • ${entry.lateMinutes} min late' : ''}',
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
    if (confirmed != true || !context.mounted) return;
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
    if (confirmed != true || !context.mounted) return;
    final result = await context.read<FlexibleAttendanceCubit>().clockOut();
    if (context.mounted && result == FixedShiftMutationResult.success) {
      ToastService.success(context, message: 'Clock-out confirmed.');
    }
  }
}

class _EligibilityTile extends StatelessWidget {
  const _EligibilityTile({
    required this.entry,
    required this.timezone,
    required this.busy,
    this.onTap,
  });
  final EligibleShiftOccurrence entry;
  final String timezone;
  final bool busy;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final status = _classification(entry.classification);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: entry.recommended
            ? Theme.of(context).colorScheme.primaryContainer
            : AppColors.field,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: entry.recommended
              ? Theme.of(context).colorScheme.primary
              : AppColors.borderColor,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          key: Key('eligible-template-${entry.template.id}'),
          onTap: busy ? null : onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          leading: Container(
            width: 8,
            height: 52,
            decoration: BoxDecoration(
              color: _color(entry.template.color),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  entry.template.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (entry.recommended)
                const Chip(
                  label: Text('Recommended'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          subtitle: Text(
            '${WorkspaceTime.time(entry.scheduledStartAt, timezone)} – ${WorkspaceTime.time(entry.scheduledEndAt, timezone)}\n${entry.operationalDate} • $status${entry.lateMinutes > 0 ? ' • ${entry.lateMinutes} min late' : ''}',
          ),
          trailing: busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(_classificationIcon(entry.classification)),
          isThreeLine: true,
        ),
      ),
    );
  }
}

class _ActiveAttendanceCard extends StatelessWidget {
  const _ActiveAttendanceCard({
    required this.attendance,
    required this.timezone,
    required this.busy,
    required this.onClockOut,
  });
  final FlexibleAttendance attendance;
  final String timezone;
  final bool busy;
  final VoidCallback onClockOut;
  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 48,
              decoration: BoxDecoration(
                color: _color(attendance.templateColor ?? '#334155'),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active attendance',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    attendance.templateName ?? 'Fixed shift',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const Icon(Icons.radio_button_checked, color: AppColors.success),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Clocked in: ${WorkspaceTime.dateTime(attendance.clockInAt, attendance.workspaceTimezone ?? timezone)}',
        ),
        if (attendance.scheduledStartAt != null &&
            attendance.scheduledEndAt != null)
          Text(
            'Schedule: ${WorkspaceTime.time(attendance.scheduledStartAt, timezone)} – ${WorkspaceTime.time(attendance.scheduledEndAt, timezone)}',
          ),
        Text(
          'Operational date: ${attendance.operationalDate ?? 'Unavailable'}',
        ),
        Text(
          '${_classification(attendance.classification ?? AttendanceClassification.unknown)}${attendance.minutesLate > 0 ? ' • ${attendance.minutesLate} min late' : ''}',
        ),
        const SizedBox(height: 6),
        StreamBuilder<int>(
          stream: Stream<int>.periodic(
            const Duration(minutes: 1),
            (value) => value,
          ),
          builder: (_, _) => Text(
            'Elapsed (display only): ${_elapsed(DateTime.now().toUtc().difference(attendance.clockInAt))}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: busy ? null : onClockOut,
            icon: busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded),
            label: const Text('Clock out'),
          ),
        ),
      ],
    ),
  );
}

String _classification(AttendanceClassification value) => switch (value) {
  AttendanceClassification.early => 'Early',
  AttendanceClassification.onTime => 'On time',
  AttendanceClassification.late => 'Late',
  AttendanceClassification.unknown => 'Status unavailable',
};
IconData _classificationIcon(AttendanceClassification value) => switch (value) {
  AttendanceClassification.early => Icons.fast_forward_rounded,
  AttendanceClassification.onTime => Icons.check_circle_outline,
  AttendanceClassification.late => Icons.warning_amber_rounded,
  AttendanceClassification.unknown => Icons.help_outline_rounded,
};
String _elapsed(Duration value) {
  final safe = value.isNegative ? Duration.zero : value;
  return '${safe.inHours}h ${safe.inMinutes.remainder(60)}m';
}

Color _color(String value) {
  final hex = value.replaceFirst('#', '');
  return hex.length == 6
      ? Color(int.tryParse('FF$hex', radix: 16) ?? 0xFF334155)
      : const Color(0xFF334155);
}
