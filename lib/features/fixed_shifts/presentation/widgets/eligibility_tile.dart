import 'package:flutter/material.dart';
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
    this.onTap,
  });
  final EligibleShiftOccurrence entry;
  final String timezone;
  final bool busy;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final status = entry.alreadyUsed
        ? 'Already used; cannot reopen'
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
            ],
          ),
          subtitle: Text(
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
                  (entry.lateMinutes > 0
                          ? ' • ${context.tr('{minutes} min late', {'minutes': '${entry.lateMinutes}'})}'
                          : '')
                      .toString(),
            }),
          ),
          trailing: busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(attendanceClassificationIcon(entry.classification)),
          isThreeLine: false,
        ),
      ),
    );
  }
}
