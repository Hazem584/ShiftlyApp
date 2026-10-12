import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/attendance_presentation.dart';

class EligibilityTile extends StatelessWidget {
  const EligibilityTile({
    super.key,
    required this.entry,
    required this.timezone,
    required this.busy,
    required this.evaluatedAt,
    this.onTap,
    this.onReview,
  });
  final EligibleShiftOccurrence entry;
  final String timezone;
  final bool busy;
  final VoidCallback? onTap;
  final VoidCallback? onReview;
  final DateTime evaluatedAt;
  @override
  Widget build(BuildContext context) {
    final ended = !entry.scheduledEndAt.isAfter(evaluatedAt);
    final missing = ended && !entry.alreadyUsed;
    final upcoming = entry.checkInWindowStart.isAfter(evaluatedAt);
    final status = entry.alreadyUsed
        ? 'Already used; cannot reopen'
        : missing
        ? 'No attendance recorded'
        : upcoming
        ? 'Check-in has not opened yet'
        : !entry.eligible
        ? 'Outside check-in window / read-only'
        : attendanceClassificationLabel(entry.classification);
    final savedTimezone = entry.timezone ?? timezone;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: entry.recommended
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: entry.recommended
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          key: Key('eligible-template-${entry.template.id}'),
          onTap: busy ? null : onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          leading: Container(
            width: 8,
            height: 52,
            decoration: BoxDecoration(
              color: attendanceTemplateColor(entry.template.color),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.template.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                context.tr(
                  entry.occurrenceKind == 'EXTRA'
                      ? 'Authorized EXTRA'
                      : entry.occurrenceKind == 'BASELINE'
                      ? 'Assigned BASELINE'
                      : 'Unknown occurrence; read-only',
                ),
              ),
              if (entry.recommended)
                Chip(
                  label: Text(context.tr('Recommended')),
                  visualDensity: VisualDensity.compact,
                ),
              if (entry.scheduleExceptionId != null)
                Text(context.tr('One-day shift change')),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.scheduleExceptionReason != null)
                Text(entry.scheduleExceptionReason!),
              Text(
                context.tr('{value1} – {value2}\n{value3} • {value4}{value5}', {
                  'value1': (WorkspaceTime.time(
                    entry.scheduledStartAt,
                    savedTimezone,
                    locale: Localizations.localeOf(context).toString(),
                  )).toString(),
                  'value2': (WorkspaceTime.time(
                    entry.scheduledEndAt,
                    savedTimezone,
                    locale: Localizations.localeOf(context).toString(),
                  )).toString(),
                  'value3': (entry.operationalDate).toString(),
                  'value4': (context.tr(status)).toString(),
                  'value5':
                      (entry.eligible &&
                                  !entry.alreadyUsed &&
                                  entry.lateMinutes > 0
                              ? ' • ${context.tr('{minutes} min late', {'minutes': '${entry.lateMinutes}'})}'
                              : '')
                          .toString(),
                }),
              ),
              if (missing) ...[
                const SizedBox(height: 8),
                Text(
                  context.tr(
                    'No attendance was recorded for {shift} on {date}. Did you attend without recording, or have an exception?',
                    {
                      'shift': entry.template.name,
                      'date': entry.operationalDate,
                    },
                  ),
                ),
                if (entry.pendingReview) ...[
                  Text(
                    context.tr(
                      'Your request is waiting for your manager’s review.',
                    ),
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => context.push('/team-work?tab=corrections'),
                    child: Text(context.tr('View my requests')),
                  ),
                ],
                if (onReview != null && !entry.pendingReview)
                  OutlinedButton.icon(
                    key: Key('review-missed-${entry.identity}'),
                    onPressed: busy ? null : onReview,
                    icon: const Icon(Icons.rate_review_outlined),
                    label: Text(context.tr('Explain absence / request review')),
                  ),
              ],
            ],
          ),
          trailing: busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  entry.alreadyUsed
                      ? Icons.check_circle_outline
                      : missing
                      ? Icons.event_busy_outlined
                      : upcoming
                      ? Icons.schedule_outlined
                      : attendanceClassificationIcon(entry.classification),
                ),
          isThreeLine: false,
        ),
      ),
    );
  }
}
