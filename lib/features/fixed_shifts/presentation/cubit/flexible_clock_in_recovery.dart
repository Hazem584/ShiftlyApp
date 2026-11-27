import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shift_cubit_helpers.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/flexible_attendance_host.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/flexible_clock_in_submitter.dart';

Future<FixedShiftMutationResult> recoverSavedFlexibleClockIn(
  FlexibleAttendanceHost host,
) async {
  final scope = host.scope;
  final pending = host.state.recovery;
  if (scope == null ||
      pending == null ||
      !pending.hasEvidence ||
      pending.userId != scope.userId ||
      pending.workspaceId != scope.workspaceId ||
      pending.membershipId != scope.membershipId) {
    return FixedShiftMutationResult.failure;
  }
  if (host.busy) return FixedShiftMutationResult.busy;
  final revision = host.beginMutation();
  final generation = host.generation;
  host.emitState(
    host.state.copyWith(
      submittingTemplateId: pending.templateId,
      loading: false,
      refreshing: false,
      clearFailure: true,
    ),
  );
  try {
    final canonical = await host.repository.findPendingAttendance(pending);
    if (!host.current(scope, generation, revision)) {
      return FixedShiftMutationResult.stale;
    }
    if (canonical != null) {
      return await submitPendingClockIn(
        host,
        scope,
        generation,
        revision,
        pending,
        recovered: canonical,
      );
    }
    if (pending.occurrenceKind == 'BASELINE') {
      final fresh = await host.repository.getEligibility(scope.workspaceId);
      if (!host.current(scope, generation, revision)) {
        return FixedShiftMutationResult.stale;
      }
      final validWindow =
          fresh.workspaceId == scope.workspaceId &&
          fresh.authorizedOccurrences.any(
            (v) =>
                pending.sameOccurrence(v) &&
                v.canClockIn &&
                v.template.workspaceId == scope.workspaceId &&
                !host.now().toUtc().isAfter(v.checkInWindowEnd),
          );
      if (!validWindow) {
        host.emitState(
          host.state.copyWith(
            clearSubmitting: true,
            failure: const Failure(
              message: 'The original baseline window is no longer available. The saved operation is retained. Contact support with the original date and saved request ID; this app has no review or date-pinned retry endpoint and it cannot be replayed against a later occurrence.',
            ),
          ),
        );
        return FixedShiftMutationResult.failure;
      }
    }
    return await submitPendingClockIn(
      host,
      scope,
      generation,
      revision,
      pending,
    );
  } catch (error) {
    if (host.current(scope, generation, revision)) {
      host.emitState(
        host.state.copyWith(
          clearSubmitting: true,
          failure: fixedShiftFailure(
            error,
            'Unable to resolve saved clock-in. Retry recovery when access is restored.',
          ),
        ),
      );
    }
    return FixedShiftMutationResult.failure;
  } finally {
    host.release(scope, generation, revision);
  }
}
