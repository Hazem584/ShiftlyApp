import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';
import 'package:shiftly/features/shifts/presentation/cubit/manager_shifts_create_mixin.dart';
import 'package:shiftly/features/shifts/presentation/cubit/manager_shifts_helper.dart';
import 'package:shiftly/features/shifts/presentation/cubit/manager_shifts_state.dart';

mixin ManagerShiftUpdateMixin on ManagerShiftsCubitBase {
  Future<ShiftMutationResult> update(
    String shiftId,
    UpdateShiftInput input,
  ) async {
    final currentScope = scope;
    if (currentScope == null) return ShiftMutationResult.failure;
    if (state.updatingId == shiftId) return ShiftMutationResult.busy;
    final current = state.records.where((i) => i.id == shiftId).firstOrNull;
    if ((input.startsAt ?? current?.startsAt) == null ||
        (input.endsAt ?? current?.endsAt) == null ||
        (input.breakMinutes ?? current?.breakMinutes) == null ||
        (input.graceMinutes ?? current?.graceMinutes) == null) {
      return ShiftMutationResult.failure;
    }
    final validation = ManagerShiftsHelper.validateUpdate(
      state,
      shiftId,
      input,
    );
    if (validation != null) {
      emit(state.copyWith(failure: validation));
      return ShiftMutationResult.failure;
    }
    final gen = generation;
    emit(state.copyWith(updatingId: shiftId, clearFailure: true));
    return _runUpdate(currentScope, gen, shiftId, input);
  }

  Future<ShiftMutationResult> _runUpdate(
    FeatureSessionScope currentScope,
    int gen,
    String shiftId,
    UpdateShiftInput input,
  ) async {
    try {
      final record = await repository.updateShift(
        currentScope.workspaceId,
        shiftId,
        input,
      );
      if (!isScopeCurrent(currentScope, gen)) return ShiftMutationResult.stale;
      if (record.workspaceId != currentScope.workspaceId) {
        emit(
          state.copyWith(
            clearUpdating: true,
            failure: ManagerShiftsHelper.invalidResponse(),
          ),
        );
        return ShiftMutationResult.failure;
      }
      emit(
        state.copyWith(
          records: ManagerShiftsHelper.upsert(state.records, record),
          selected: state.selected?.id == record.id ? record : state.selected,
          clearUpdating: true,
        ),
      );
      onDashboardChanged?.call();
      return ShiftMutationResult.success;
    } catch (error) {
      if (!isScopeCurrent(currentScope, gen)) return ShiftMutationResult.stale;
      emit(
        state.copyWith(
          clearUpdating: true,
          failure: ManagerShiftsHelper.failure(
            error,
            'Unable to update the shift.',
          ),
        ),
      );
      return ShiftMutationResult.failure;
    }
  }
}
