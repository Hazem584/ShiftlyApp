import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';
import 'package:shiftly/features/shifts/presentation/cubit/manager_shifts_helper.dart';
import 'package:shiftly/features/shifts/presentation/cubit/manager_shifts_state.dart';

abstract class ManagerShiftsCubitBase extends Cubit<ManagerShiftsState> {
  ManagerShiftsCubitBase(this.repository, {this.onDashboardChanged})
    : super(const ManagerShiftsState());

  final ShiftRepository repository;
  final void Function()? onDashboardChanged;
  FeatureSessionScope? scope;
  var generation = 0;
  var requestId = 0;

  bool isCurrent(FeatureSessionScope s, int g, int r) =>
      isScopeCurrent(s, g) && requestId == r;

  bool isScopeCurrent(FeatureSessionScope s, int g) =>
      !isClosed && scope == s && generation == g;
}

mixin ManagerShiftMutations on ManagerShiftsCubitBase {
  Future<ShiftMutationResult> create(CreateShiftInput input) async {
    final currentScope = scope;
    if (currentScope == null) return ShiftMutationResult.failure;
    if (state.creating) return ShiftMutationResult.busy;
    final validation = ManagerShiftsHelper.validateShift(
      startsAt: input.startsAt,
      endsAt: input.endsAt,
      breakMinutes: input.breakMinutes,
      graceMinutes: input.graceMinutes,
    );
    if (validation != null) {
      emit(state.copyWith(failure: validation));
      return ShiftMutationResult.failure;
    }
    final gen = generation;
    emit(state.copyWith(creating: true, clearFailure: true));
    return _runCreate(currentScope, gen, input);
  }

  Future<ShiftMutationResult> _runCreate(
    FeatureSessionScope currentScope,
    int gen,
    CreateShiftInput input,
  ) async {
    try {
      final record = await repository.createShift(
        currentScope.workspaceId,
        input,
      );
      if (!isScopeCurrent(currentScope, gen)) return ShiftMutationResult.stale;
      if (record.workspaceId != currentScope.workspaceId) {
        emit(
          state.copyWith(
            creating: false,
            failure: ManagerShiftsHelper.invalidResponse(),
          ),
        );
        return ShiftMutationResult.failure;
      }
      final exists = state.records.any((item) => item.id == record.id);
      emit(
        state.copyWith(
          records: ManagerShiftsHelper.upsert(state.records, record),
          total: exists ? state.total : state.total + 1,
          creating: false,
        ),
      );
      onDashboardChanged?.call();
      return ShiftMutationResult.success;
    } catch (error) {
      if (!isScopeCurrent(currentScope, gen)) return ShiftMutationResult.stale;
      emit(
        state.copyWith(
          creating: false,
          failure: ManagerShiftsHelper.failure(
            error,
            'Unable to create the shift.',
          ),
        ),
      );
      return ShiftMutationResult.failure;
    }
  }
}
