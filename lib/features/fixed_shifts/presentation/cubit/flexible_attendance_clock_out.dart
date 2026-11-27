import 'dart:async';

import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shift_cubit_helpers.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/flexible_attendance_host.dart';

Future<FixedShiftMutationResult> performFlexibleClockOut(
  FlexibleAttendanceHost host,
) async {
  final scope = host.scope;
  final active = host.state.current;
  if (scope == null ||
      active == null ||
      !active.isActionable ||
      !active.isOpen) {
    return FixedShiftMutationResult.failure;
  }
  if (host.busy) return FixedShiftMutationResult.busy;
  final revision = host.beginMutation();
  final generation = host.generation;
  host.emitState(
    host.state.copyWith(
      clockingOut: true,
      loading: false,
      refreshing: false,
      clearFailure: true,
    ),
  );
  try {
    final canonical = await host.repository.flexibleClockOut(active.id);
    if (!host.current(scope, generation, revision)) {
      return FixedShiftMutationResult.stale;
    }
    if (canonical.id != active.id ||
        canonical.workspaceId != scope.workspaceId ||
        canonical.employeeMembershipId != scope.membershipId ||
        canonical.clockOutAt == null) {
      throw const FormatException('Invalid clock-out response');
    }
    host.emitState(
      host.state.copyWith(
        current: canonical,
        clockingOut: false,
        loading: false,
        refreshing: false,
        recoveryBlocked: true,
      ),
    );
    unawaited(host.refreshAfterMutation(scope, generation, revision));
    return FixedShiftMutationResult.success;
  } catch (error) {
    if (host.current(scope, generation, revision)) {
      host.emitState(
        host.state.copyWith(
          clockingOut: false,
          failure: fixedShiftFailure(error, 'Unable to clock out.'),
        ),
      );
    }
    return FixedShiftMutationResult.failure;
  } finally {
    host.release(scope, generation, revision);
  }
}

Future<void> refreshAfterAttendanceMutation(
  FlexibleAttendanceHost host,
  FeatureSessionScope scope,
  int generation,
  int revision,
  FutureOr<void> Function()? onAttendanceChanged,
) async {
  try {
    await onAttendanceChanged?.call();
  } catch (_) {}
  if (!host.current(scope, generation, revision)) return;
  try {
    final eligibility = await host.repository.getEligibility(scope.workspaceId);
    if (!host.current(scope, generation, revision)) return;
    if (eligibility.workspaceId != scope.workspaceId) {
      throw const FormatException('Cross-scope eligibility');
    }
    host.emitState(
      host.state.copyWith(
        eligibility: eligibility,
        recoveryBlocked:
            host.state.recovery != null || host.state.legacyReviewRequired,
      ),
    );
  } catch (_) {
    if (host.current(scope, generation, revision)) {
      host.emitState(
        host.state.copyWith(
          recoveryBlocked: true,
          failure: const Failure(
            message:
                'Attendance saved. Schedule refresh failed; retry refresh before another clock-in.',
          ),
        ),
      );
    }
  }
}
