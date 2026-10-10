import 'dart:async';

import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/fixed_shifts/domain/policies/confirmed_mutation_rejection.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shift_cubit_helpers.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';

import 'flexible_attendance_host.dart';

class FlexibleClockInController {
  FlexibleClockInController(this.host);
  final FlexibleAttendanceHost host;
  Future<FixedShiftMutationResult> clockIn(
    EligibleShiftOccurrence occurrence,
  ) async {
    if (host.busy) {
      return FixedShiftMutationResult.busy;
    }
    final scope = host.scope;
    if (scope == null ||
        !occurrence.canClockIn ||
        host.state.recoveryBlocked ||
        host.state.legacyReviewRequired ||
        host.state.loading ||
        host.state.refreshing ||
        host.state.failure != null ||
        !const {
          'ASSIGNED',
          'SHIFT_ASSIGNMENT_REQUIRED',
        }.contains(host.state.eligibility?.status) ||
        host.consumed.contains(occurrence.identity)) {
      return FixedShiftMutationResult.failure;
    }
    if (host.busy ||
        host.state.current?.isOpen == true ||
        host.state.eligibility?.openAttendanceId != null) {
      return FixedShiftMutationResult.busy;
    }
    if (!(host.state.eligibility?.authorizedOccurrences.any(
          (v) =>
              v.identity == occurrence.identity &&
              v.canClockIn &&
              v.template.workspaceId == scope.workspaceId,
        ) ??
        false)) {
      return FixedShiftMutationResult.failure;
    }
    final revision = host.beginMutation();
    final generation = host.generation;
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
          !fresh.authorizedOccurrences.any(
            (v) =>
                v.identity == occurrence.identity &&
                v.canClockIn &&
                v.template.workspaceId == scope.workspaceId,
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
      return await _submitPending(scope, generation, revision, pending);
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

  Future<FixedShiftMutationResult> recoverClockIn() async {
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
    if (host.busy) {
      return FixedShiftMutationResult.busy;
    }
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
        return await _submitPending(
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
        if (fresh.workspaceId != scope.workspaceId ||
            !fresh.authorizedOccurrences.any(
              (v) =>
                  pending.sameOccurrence(v) &&
                  v.canClockIn &&
                  v.template.workspaceId == scope.workspaceId &&
                  !host.now().toUtc().isAfter(v.checkInWindowEnd),
            )) {
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
      return await _submitPending(scope, generation, revision, pending);
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

  Future<FixedShiftMutationResult> _submitPending(
    FeatureSessionScope scope,
    int generation,
    int revision,
    PendingClockIn pending, {
    FlexibleAttendance? recovered,
  }) async {
    try {
      final canonical =
          recovered ??
          await host.repository.flexibleClockIn(
            workspaceId: pending.workspaceId,
            shiftTemplateId: pending.templateId,
            clientAttendanceId: pending.clientAttendanceId,
            assignmentId: pending.assignmentId,
            extraAuthorizationId: pending.extraAuthorizationId,
          );
      if (!host.current(scope, generation, revision)) {
        return FixedShiftMutationResult.stale;
      }
      if (canonical.workspaceId != scope.workspaceId ||
          canonical.employeeMembershipId != scope.membershipId ||
          canonical.shiftTemplateId != pending.templateId ||
          canonical.clientAttendanceId != pending.clientAttendanceId ||
          canonical.occurrenceKind != pending.occurrenceKind ||
          canonical.assignmentId != pending.assignmentId ||
          canonical.extraAuthorizationId != pending.extraAuthorizationId ||
          canonical.operationalDate != pending.operationalDate) {
        throw const FormatException('Invalid canonical attendance');
      }
      host.consumed.add(
        '${pending.occurrenceKind}|${pending.templateId}|${pending.assignmentId}|${pending.extraAuthorizationId}|${pending.operationalDate}',
      );
      host.emitState(
        host.state.copyWith(
          current: canonical,
          clearSubmitting: true,
          loading: false,
          refreshing: false,
          clearFailure: true,
        ),
      );
      try {
        await host.repository.clearPendingClockIn(pending);
        if (host.current(scope, generation, revision)) {
          host.emitState(
            host.state.copyWith(
              clearRecovery: true,
              recoveryBlocked: host.state.legacyReviewRequired,
            ),
          );
        }
      } catch (_) {}
      if (host.current(scope, generation, revision)) {
        unawaited(host.refreshAfterMutation(scope, generation, revision));
      }
      return FixedShiftMutationResult.success;
    } catch (error) {
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
            recoveryBlocked: true,
            clearSubmitting: true,
            failure: fixedShiftFailure(
              error,
              'Refresh before another clock-in.',
            ),
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
  }
}
