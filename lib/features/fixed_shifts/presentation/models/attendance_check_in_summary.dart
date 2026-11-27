import 'package:shiftly/features/fixed_shifts/domain/entities/eligible_shift_occurrence.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/flexible_attendance_state.dart';

import 'attendance_status_summary.dart';

AttendanceStatusSummary? availableCheckInSummary(
  FlexibleAttendanceState state,
  String actionLocation,
) {
  final entries =
      state.eligibility?.authorizedOccurrences ??
      const <EligibleShiftOccurrence>[];
  final available = entries.where((entry) => entry.canClockIn).toList()
    ..sort((a, b) {
      if (a.recommended != b.recommended) return a.recommended ? -1 : 1;
      return a.scheduledStartAt.compareTo(b.scheduledStartAt);
    });
  if (available.isNotEmpty) {
    return AttendanceStatusSummary(
      title: 'Ready to clock in',
      message: 'Choose {name} {location} to start your attendance.',
      arguments: {
        'name': available.first.template.name,
        'location': actionLocation,
      },
      tone: AttendanceStatusTone.ready,
      occurrence: available.first,
    );
  }
  final evaluatedAt = state.eligibility?.evaluatedAt;
  final upcoming =
      entries
          .where(
            (entry) =>
                evaluatedAt != null &&
                !entry.alreadyUsed &&
                entry.template.active &&
                (entry.occurrenceKind == 'BASELINE' ||
                    entry.occurrenceKind == 'EXTRA') &&
                entry.checkInWindowStart.isAfter(evaluatedAt) &&
                entry.scheduledEndAt.isAfter(entry.scheduledStartAt),
          )
          .toList()
        ..sort((a, b) => a.checkInWindowStart.compareTo(b.checkInWindowStart));
  if (upcoming.isNotEmpty) {
    return AttendanceStatusSummary(
      title: 'Your next check-in window',
      message: 'Your workspace lists {name} as upcoming. Refresh when its check-in window opens.',
      arguments: {'name': upcoming.first.template.name},
      occurrence: upcoming.first,
    );
  }
  return null;
}
