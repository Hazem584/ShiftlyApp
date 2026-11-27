import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/eligible_shift_occurrence.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';

class EmployeeShiftStatusEval {
  EmployeeShiftStatusEval(this.state, EligibleShiftOccurrence fallback) {
    final live = state.eligibility?.authorizedOccurrences
        .where((item) => item.identity == fallback.identity)
        .firstOrNull;
    entry = live ?? fallback;
    hasOpen =
        state.current?.isOpen == true ||
        state.eligibility?.openAttendanceId != null;
    safe =
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
        evaluated != null && entry.checkInWindowStart.isAfter(evaluated);
    final missing =
        evaluated != null &&
        !entry.scheduledEndAt.isAfter(evaluated) &&
        !entry.alreadyUsed;
    canReview =
        safe &&
        missing &&
        !entry.pendingReview &&
        getIt.isRegistered<TeamWorkRepository>() &&
        ((entry.occurrenceKind == 'BASELINE' && entry.assignmentId != null) ||
            (entry.occurrenceKind == 'EXTRA' &&
                entry.extraAuthorizationId != null));
    status = hasOpen
        ? 'You have an open attendance'
        : entry.alreadyUsed
        ? 'This shift is already recorded'
        : entry.pendingReview
        ? 'Your request is waiting for your manager’s review.'
        : upcoming
        ? 'Check-in not open yet'
        : evaluated != null && entry.checkInWindowEnd.isBefore(evaluated)
        ? 'The check-in window has closed.'
        : !entry.canClockIn
        ? 'No check-in available right now'
        : null;
  }

  final FlexibleAttendanceState state;
  late final EligibleShiftOccurrence entry;
  late final bool hasOpen;
  late final bool safe;
  late final bool canReview;
  late final String? status;
}
