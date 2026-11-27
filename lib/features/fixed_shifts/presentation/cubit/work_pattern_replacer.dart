import 'dart:async';

import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/extra_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shift_cubit_helpers.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';

Future<FixedShiftMutationResult> performWorkPatternReplace({
  required FixedShiftRepository repository,
  required FeatureSessionScope? scope,
  required String? workspaceId,
  required String? membershipId,
  required int generation,
  required WorkPatternState Function() getState,
  required void Function(WorkPatternState) emitState,
  required bool Function(String, String, int) isCurrent,
  required FutureOr<void> Function()? onChanged,
  required Future<void> Function({bool retain}) reload,
  required String shiftTemplateId,
  required Set<int> weekdays,
  required String effectiveFrom,
}) async {
  if (workspaceId == null ||
      membershipId == null ||
      scope?.isManager != true ||
      scope?.workspaceId != workspaceId) {
    return FixedShiftMutationResult.failure;
  }
  final currentState = getState();
  if (currentState.saving || currentState.loading) {
    return FixedShiftMutationResult.busy;
  }
  if (weekdays.isEmpty || weekdays.any((v) => v < 0 || v > 6)) {
    emitState(
      WorkPatternState(
        loading: false,
        history: currentState.history,
        failure: const Failure(
          message: 'Select at least one working day.',
          kind: FailureKind.validation,
        ),
      ),
    );
    return FixedShiftMutationResult.failure;
  }
  emitState(
    WorkPatternState(
      loading: false,
      saving: true,
      history: currentState.history,
    ),
  );
  try {
    if (repository is ExtraShiftRepository &&
        await (repository as ExtraShiftRepository).readExtraIntent(scope!) !=
            null) {
      if (isCurrent(workspaceId, membershipId, generation)) {
        emitState(
          WorkPatternState(
            loading: false,
            history: getState().history,
            failure: const Failure(
              message:
                  'Recover the saved extra operation before replacing an assignment.',
            ),
          ),
        );
      }
      return FixedShiftMutationResult.failure;
    }
    if (!isCurrent(workspaceId, membershipId, generation)) {
      return FixedShiftMutationResult.stale;
    }
    final canonical = await repository.replaceWorkPattern(
      workspaceId,
      membershipId,
      shiftTemplateId: shiftTemplateId,
      expectedWeekdays: weekdays.toList(),
      effectiveFrom: effectiveFrom,
    );
    if (!isCurrent(workspaceId, membershipId, generation)) {
      return FixedShiftMutationResult.stale;
    }
    if (canonical.workspaceId != workspaceId ||
        canonical.employeeMembershipId != membershipId ||
        canonical.shiftTemplateId != shiftTemplateId) {
      throw const FormatException('Invalid assignment response');
    }
    final history = getState().history;
    final localToday = WorkspaceTime.dateKey(
      DateTime.now().toUtc(),
      scope!.timezone,
    );
    emitState(
      WorkPatternState(
        loading: false,
        history: WorkPatternHistory(
          current: canonical.effectiveFrom.compareTo(localToday) <= 0
              ? canonical
              : history?.current,
          history: [
            canonical,
            ...?history?.history.where((v) => v.id != canonical.id),
          ],
          pagination: history?.pagination,
        ),
      ),
    );
    try {
      await onChanged?.call();
    } catch (_) {}
    if (isCurrent(workspaceId, membershipId, generation)) {
      await reload(retain: true);
    }
    return FixedShiftMutationResult.success;
  } catch (error) {
    if (!isCurrent(workspaceId, membershipId, generation)) {
      return FixedShiftMutationResult.stale;
    }
    emitState(
      WorkPatternState(
        loading: false,
        history: getState().history,
        failure: fixedShiftFailure(
          error,
          'Unable to replace the work pattern.',
        ),
      ),
    );
    return FixedShiftMutationResult.failure;
  }
}
