import 'package:shiftly/features/fixed_shifts/domain/entities/eligible_shift_occurrence.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/flexible_attendance_state.dart';

import 'attendance_check_in_summary.dart';
import 'attendance_open_summary.dart';

enum AttendanceStatusTone { neutral, ready, active, attention }

class AttendanceStatusSummary {
  const AttendanceStatusSummary({
    required this.title,
    required this.message,
    this.tone = AttendanceStatusTone.neutral,
    this.occurrence,
    this.arguments = const {},
  });

  final String title;
  final String message;
  final AttendanceStatusTone tone;
  final EligibleShiftOccurrence? occurrence;
  final Map<String, String> arguments;

  factory AttendanceStatusSummary.fromState(
    FlexibleAttendanceState state, {
    String actionLocation = 'below',
  }) {
    if (state.recovery != null) {
      return AttendanceStatusSummary(
        title: 'Your clock-in needs confirmation',
        message: 'Your last request is saved. Confirm its outcome {location} before starting another shift.',
        arguments: {'location': actionLocation},
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
      return openAttendanceSummary(
        current,
        hasFailure: state.failure != null,
        actionLocation: actionLocation,
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
      return AttendanceStatusSummary(
        title: 'Your attendance needs a status check',
        message: 'Refresh or review the saved attendance {location} before clocking in again.',
        arguments: {'location': actionLocation},
        tone: AttendanceStatusTone.attention,
      );
    }
    final checkIn = availableCheckInSummary(state, actionLocation);
    if (checkIn != null) return checkIn;
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
    return AttendanceStatusSummary(
      title: 'No check-in available right now',
      message: 'Check your assigned schedule {location}. If a shift is missing, ask your manager to review your assignment.',
      arguments: {'location': actionLocation},
    );
  }
}
