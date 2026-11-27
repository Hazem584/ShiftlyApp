import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/fixed_shifts/domain/policies/confirmed_mutation_rejection.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shift_cubit_helpers.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/flexible_attendance_host.dart';

bool canInitiateFlexibleClockIn(
  FlexibleAttendanceHost host,
  FeatureSessionScope? scope,
  EligibleShiftOccurrence occurrence,
) =>
    scope != null &&
    occurrence.canClockIn &&
    !host.state.recoveryBlocked &&
    !host.state.legacyReviewRequired &&
    !host.state.loading &&
    !host.state.refreshing &&
    host.state.failure == null &&
    const {
      'ASSIGNED',
      'SHIFT_ASSIGNMENT_REQUIRED',
    }.contains(host.state.eligibility?.status) &&
    !host.consumed.contains(occurrence.identity);

bool isOccurrenceAuthorizedForScope(
  TemplateEligibility? eligibility,
  String workspaceId,
  EligibleShiftOccurrence occurrence,
) =>
    eligibility?.authorizedOccurrences.any(
      (v) =>
          v.identity == occurrence.identity &&
          v.canClockIn &&
          v.template.workspaceId == workspaceId,
    ) ??
    false;

Future<FixedShiftMutationResult> handlePendingClockInSubmissionError(
  FlexibleAttendanceHost host,
  FeatureSessionScope scope,
  int generation,
  int revision,
  PendingClockIn pending,
  Object error,
) async {
  if (!host.current(scope, generation, revision)) {
    return FixedShiftMutationResult.stale;
  }
  if (confirmedMutationRejection(error)) {
    var cleared = false;
    try {
      await host.repository.clearPendingClockIn(pending);
      cleared = true;
    } catch (_) {}
    if (!host.current(scope, generation, revision)) {
      return FixedShiftMutationResult.stale;
    }
    host.emitState(
      host.state.copyWith(
        clearRecovery: cleared,
        recoveryBlocked: !cleared,
        clearSubmitting: true,
        failure: fixedShiftFailure(error, 'Refresh before another clock-in.'),
      ),
    );
  } else {
    host.emitState(
      host.state.copyWith(
        recovery: pending,
        recoveryBlocked: true,
        clearSubmitting: true,
        failure: fixedShiftFailure(
          error,
          'Clock-in may have succeeded. Recover the saved operation before starting another shift.',
        ),
      ),
    );
  }
  return FixedShiftMutationResult.failure;
}
