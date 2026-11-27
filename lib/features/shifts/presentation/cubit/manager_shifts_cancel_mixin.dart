import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';
import 'package:shiftly/features/shifts/presentation/cubit/manager_shifts_create_mixin.dart';
import 'package:shiftly/features/shifts/presentation/cubit/manager_shifts_helper.dart';
import 'package:shiftly/features/shifts/presentation/cubit/manager_shifts_state.dart';

mixin ManagerShiftCancelMixin on ManagerShiftsCubitBase {
  Future<ShiftMutationResult> cancel(String shiftId) async {
    final currentScope = scope;
    if (currentScope == null) return ShiftMutationResult.failure;
    if (state.cancellingId == shiftId) return ShiftMutationResult.busy;
    final gen = generation;
    emit(state.copyWith(cancellingId: shiftId, clearFailure: true));
    try {
      final record = await repository.cancelShift(
        currentScope.workspaceId,
        shiftId,
      );
      if (!isScopeCurrent(currentScope, gen)) return ShiftMutationResult.stale;
      if (record.workspaceId != currentScope.workspaceId ||
          record.status != ShiftStatus.cancelled) {
        emit(
          state.copyWith(
            clearCancelling: true,
            failure: ManagerShiftsHelper.invalidResponse(),
          ),
        );
        return ShiftMutationResult.failure;
      }
      emit(
        state.copyWith(
          records: ManagerShiftsHelper.upsert(state.records, record),
          selected: state.selected?.id == record.id ? record : state.selected,
          clearCancelling: true,
        ),
      );
      onDashboardChanged?.call();
      return ShiftMutationResult.success;
    } catch (error) {
      if (!isScopeCurrent(currentScope, gen)) return ShiftMutationResult.stale;
      emit(
        state.copyWith(
          clearCancelling: true,
          failure: ManagerShiftsHelper.failure(
            error,
            'Unable to cancel the shift.',
          ),
        ),
      );
      return ShiftMutationResult.failure;
    }
  }

  Future<ShiftRecord?> loadDetails(String shiftId) async {
    final currentScope = scope;
    if (currentScope == null || state.detailLoading) return null;
    final gen = generation;
    emit(state.copyWith(detailLoading: true, clearFailure: true));
    try {
      final record = await repository.getWorkspaceShift(
        currentScope.workspaceId,
        shiftId,
      );
      if (!isScopeCurrent(currentScope, gen) ||
          record.workspaceId != currentScope.workspaceId) {
        return null;
      }
      emit(state.copyWith(selected: record, detailLoading: false));
      return record;
    } catch (error) {
      if (!isScopeCurrent(currentScope, gen)) return null;
      emit(
        state.copyWith(
          detailLoading: false,
          failure: ManagerShiftsHelper.failure(
            error,
            'Unable to load shift details.',
          ),
        ),
      );
      return null;
    }
  }
}
