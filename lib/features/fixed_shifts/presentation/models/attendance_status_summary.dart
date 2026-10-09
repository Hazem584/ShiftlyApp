import 'package:shiftly/features/fixed_shifts/domain/entities/attendance_source.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/eligible_shift_occurrence.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/flexible_attendance_state.dart';

enum AttendanceStatusTone { neutral, ready, active, attention }

class AttendanceStatusSummary {
  const AttendanceStatusSummary({
    required this.title,
    required this.message,
    this.tone = AttendanceStatusTone.neutral,
    this.occurrence,
  });

  final String title;
  final String message;
  final AttendanceStatusTone tone;
  final EligibleShiftOccurrence? occurrence;

  factory AttendanceStatusSummary.fromState(FlexibleAttendanceState state) {
    if (state.recovery != null) {
      return const AttendanceStatusSummary(
        title: 'Your clock-in needs confirmation',
        message: 'Your last request is saved. Confirm its outcome below before starting another shift.',
        tone: AttendanceStatusTone.attention,
      );
    }
    if (state.submittingTemplateId != null || state.clockingOut) {
      return AttendanceStatusSummary(
        title: state.clockingOut
            ? 'Confirming your clock-out'
            : 'Confirming your clock-in',
        message: 'Waiting for your workspace to confirm the attendance change.',
      );
    }
    final current = state.current;
    if (current != null && current.isOpen) {
      return AttendanceStatusSummary(
        title: current.isActionable
            ? 'You are clocked in'
            : 'An earlier attendance is still open',
        message: current.isActionable
            ? state.failure != null
                  ? 'Your last confirmed status is clocked in. Refresh to confirm the latest status before finishing.'
                  : 'When you finish working, use Clock out below.'
            : current.source == AttendanceSource.legacyShift
            ? 'Open Earlier shifts & clock-out to finish this attendance.'
            : 'Refresh your attendance before taking another action.',
        tone: current.isActionable
            ? AttendanceStatusTone.active
            : AttendanceStatusTone.attention,
      );
    }
    if (state.loading || state.refreshing) {
      return const AttendanceStatusSummary(
        title: 'Checking your attendance',
        message: 'Loading your latest status and available shifts.',
      );
    }
    if (state.eligibility == null ||
        state.failure != null ||
        state.recoveryBlocked ||
        state.eligibility?.openAttendanceId != null ||
        state.legacyReviewRequired) {
      return const AttendanceStatusSummary(
        title: 'Your attendance needs a status check',
        message: 'Refresh or review the saved attendance below before clocking in again.',
        tone: AttendanceStatusTone.attention,
      );
    }
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
        message:
            'Choose ${available.first.template.name} below to start your attendance.',
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
          ..sort(
            (a, b) => a.checkInWindowStart.compareTo(b.checkInWindowStart),
          );
    if (upcoming.isNotEmpty) {
      return AttendanceStatusSummary(
        title: 'Your next check-in window',
        message:
            'Your workspace lists ${upcoming.first.template.name} as upcoming. Refresh when its check-in window opens.',
        occurrence: upcoming.first,
      );
    }
    if (state.eligibility?.status == 'SHIFT_ASSIGNMENT_REQUIRED') {
      return const AttendanceStatusSummary(
        title: 'No regular shift assigned yet',
        message: 'Ask your manager to assign your regular shift. Extra shifts need separate authorization.',
      );
    }
    if (current != null && !current.isOpen) {
      return const AttendanceStatusSummary(
        title: 'Your last attendance is closed',
        message: 'No new check-in is available right now. Refresh to check your next authorized shift.',
      );
    }
    return const AttendanceStatusSummary(
      title: 'No check-in available right now',
      message: 'Check your assigned schedule below. If a shift is missing, ask your manager to review your assignment.',
    );
  }
}
