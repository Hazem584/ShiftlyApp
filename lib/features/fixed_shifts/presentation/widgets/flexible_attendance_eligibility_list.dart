import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/attendance_presentation.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/eligibility_tile.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/flexible_attendance_actions.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/flexible_clock_in_dialog.dart';

List<Widget> buildEmptyEligibilitySection(
  BuildContext context,
  FlexibleAttendanceState state,
) => [
  const SizedBox(height: 10),
  Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        Icons.event_busy_outlined,
        color: AppPalette.of(context).textSecondary,
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
  if (state.templates.isNotEmpty && state.eligibility?.status == 'ASSIGNED') ...[
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
              backgroundColor: attendanceTemplateColor(template.color),
            ),
            label: Text(template.name, overflow: TextOverflow.ellipsis),
          ),
      ],
    ),
  ],
];

List<Widget> buildEligibilityEntriesSection(
  BuildContext context,
  FlexibleAttendanceState state,
  List<EligibleShiftOccurrence> entries,
  String timezone,
) {
  final canAct =
      !state.recoveryBlocked &&
      !state.refreshing &&
      state.failure == null &&
      state.eligibility?.openAttendanceId == null;
  final evaluatedAt = state.eligibility!.evaluatedAt;
  return [
    const SizedBox(height: 10),
    for (final entry in entries) ...[
      EligibilityTile(
        entry: entry,
        timezone: timezone,
        busy: state.submittingTemplateId != null,
        evaluatedAt: evaluatedAt,
        onReview: _canReview(entry, evaluatedAt, canAct)
            ? () => requestMissedAttendanceReview(
                context,
                entry,
                state.eligibility!.workspaceId,
                timezone,
              )
            : null,
        onTap: entry.canClockIn && canAct
            ? () => confirmFlexibleClockIn(context, entry, timezone)
            : null,
      ),
      if (entry != entries.last) const SizedBox(height: 9),
    ],
  ];
}

bool _canReview(
  EligibleShiftOccurrence entry,
  DateTime evaluatedAt,
  bool canAct,
) =>
    canAct &&
    !entry.alreadyUsed &&
    !entry.pendingReview &&
    !entry.scheduledEndAt.isAfter(evaluatedAt) &&
    ((entry.occurrenceKind == 'BASELINE' &&
            entry.assignmentId != null &&
            entry.extraAuthorizationId == null) ||
        (entry.occurrenceKind == 'EXTRA' &&
            entry.extraAuthorizationId != null &&
            entry.assignmentId == null));
