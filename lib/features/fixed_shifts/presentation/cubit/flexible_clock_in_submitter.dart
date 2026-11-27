import 'dart:async';

import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/flexible_attendance_host.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/flexible_clock_in_helpers.dart';

Future<FixedShiftMutationResult> submitPendingClockIn(
  FlexibleAttendanceHost host,
  FeatureSessionScope scope,
  int generation,
  int revision,
  PendingClockIn pending, {
  FlexibleAttendance? recovered,
}) async {
  try {
    final location = recovered == null
        ? await host.readLocation(requiredForPunch: true)
        : null;
    if (!host.current(scope, generation, revision)) {
      return FixedShiftMutationResult.stale;
    }
    final canonical =
        recovered ??
        await host.repository.flexibleClockIn(
          workspaceId: pending.workspaceId,
          shiftTemplateId: pending.templateId,
          clientAttendanceId: pending.clientAttendanceId,
          assignmentId: pending.assignmentId,
          extraAuthorizationId: pending.extraAuthorizationId,
          location: location,
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
    return handlePendingClockInSubmissionError(
      host,
      scope,
      generation,
      revision,
      pending,
      error,
    );
  }
}
