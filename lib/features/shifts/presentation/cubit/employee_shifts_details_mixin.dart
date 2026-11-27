import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';
import 'package:shiftly/features/shifts/presentation/cubit/employee_shifts_base.dart';

mixin EmployeeShiftDetailsMixin on EmployeeShiftsCubitBase {
  Future<ShiftRecord?> loadDetails(String shiftId) async {
    final currentScope = scope;
    if (currentScope == null || state.detailLoading) return null;
    final gen = generation;
    emit(state.copyWith(detailLoading: true, clearFailure: true));
    try {
      final record = await shifts.getMyShift(shiftId);
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
          failure: failure(error, 'Unable to load shift details.'),
        ),
      );
      return null;
    }
  }

  Future<void> loadMore() async {
    final currentScope = scope, previous = state;
    if (currentScope == null || previous.loadingMore || !previous.hasMore) {
      return;
    }
    final gen = generation, req = ++requestId;
    emit(previous.copyWith(loadingMore: true, clearFailure: true));
    try {
      final page = await shifts.listMyShifts(
        currentScope.workspaceId,
        previous.query.copyWith(page: previous.page + 1),
      );
      if (!isCurrent(currentScope, gen, req)) return;
      final ids = previous.records.map((item) => item.id).toSet();
      emit(
        previous.copyWith(
          records: [
            ...previous.records,
            ...page.data.where(
              (i) => i.workspaceId == currentScope.workspaceId && ids.add(i.id),
            ),
          ],
          page: page.pagination.page,
          totalPages: page.pagination.totalPages,
          loadingMore: false,
        ),
      );
    } catch (error) {
      if (!isCurrent(currentScope, gen, req)) return;
      emit(
        previous.copyWith(
          loadingMore: false,
          failure: failure(error, 'Unable to load more shifts.'),
        ),
      );
    }
  }
}
