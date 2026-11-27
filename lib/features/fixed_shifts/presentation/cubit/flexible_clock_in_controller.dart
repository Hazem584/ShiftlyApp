import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shift_cubit_helpers.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/flexible_attendance_host.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/flexible_clock_in_helpers.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/flexible_clock_in_recovery.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/flexible_clock_in_submitter.dart';

class FlexibleClockInController {
  FlexibleClockInController(this.host);
  final FlexibleAttendanceHost host;

  Future<FixedShiftMutationResult> recoverClockIn() =>
      recoverSavedFlexibleClockIn(host);

  Future<FixedShiftMutationResult> clockIn(
    EligibleShiftOccurrence occurrence,
  ) async {
    if (host.busy) return FixedShiftMutationResult.busy;
    final scope = host.scope;
    if (!canInitiateFlexibleClockIn(host, scope, occurrence)) {
      return FixedShiftMutationResult.failure;
    }
    if (host.busy ||
        host.state.current?.isOpen == true ||
        host.state.eligibility?.openAttendanceId != null) {
      return FixedShiftMutationResult.busy;
    }
    if (!isOccurrenceAuthorizedForScope(
      host.state.eligibility,
      scope!.workspaceId,
      occurrence,
    )) {
      return FixedShiftMutationResult.failure;
    }
    final revision = host.beginMutation(), generation = host.generation;
    host.emitState(
      host.state.copyWith(
        submittingTemplateId: occurrence.template.id,
        loading: false,
        refreshing: false,
        clearFailure: true,
      ),
    );
    try {
      final stored = await host.repository.loadPendingClockIn(
        userId: scope.userId,
        workspaceId: scope.workspaceId,
        membershipId: scope.membershipId,
        templateId: occurrence.template.id,
      );
      if (!host.current(scope, generation, revision)) {
        return FixedShiftMutationResult.stale;
      }
      if (stored != null) {
        host.emitState(
          host.state.copyWith(
            recovery: stored,
            recoveryBlocked: true,
            clearSubmitting: true,
          ),
        );
        return FixedShiftMutationResult.failure;
      }
      final fresh = await host.repository.getEligibility(scope.workspaceId);
      if (!host.current(scope, generation, revision)) {
        return FixedShiftMutationResult.stale;
      }
      if (fresh.workspaceId != scope.workspaceId ||
          fresh.openAttendanceId != null ||
          !isOccurrenceAuthorizedForScope(
            fresh,
            scope.workspaceId,
            occurrence,
          )) {
        host.emitState(
          host.state.copyWith(eligibility: fresh, clearSubmitting: true),
        );
        return FixedShiftMutationResult.failure;
      }
      final pending = PendingClockIn(
        userId: scope.userId,
        workspaceId: scope.workspaceId,
        membershipId: scope.membershipId,
        templateId: occurrence.template.id,
        clientAttendanceId: host.newRequestId(),
        occurrenceKind: occurrence.occurrenceKind,
        assignmentId: occurrence.assignmentId,
        extraAuthorizationId: occurrence.extraAuthorizationId,
        operationalDate: occurrence.operationalDate,
      );
      await host.repository.savePendingClockIn(pending);
      if (!host.current(scope, generation, revision)) {
        return FixedShiftMutationResult.stale;
      }
      host.emitState(
        host.state.copyWith(recovery: pending, recoveryBlocked: true),
      );
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
            recoveryBlocked: true,
            failure: fixedShiftFailure(
              error,
              'Clock-in recovery needs review. Refresh or contact your manager.',
            ),
          ),
        );
      }
      return FixedShiftMutationResult.failure;
    } finally {
      host.release(scope, generation, revision);
    }
  }
}
