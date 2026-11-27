import 'package:shiftly/features/shifts/presentation/cubit/manager_shifts_create_mixin.dart';
import 'package:shiftly/features/shifts/presentation/cubit/manager_shifts_helper.dart';

mixin ManagerShiftsLoadMoreMixin on ManagerShiftsCubitBase {
  Future<void> loadMore() async {
    final currentScope = scope, previous = state;
    if (currentScope == null || previous.loadingMore || !previous.hasMore) {
      return;
    }
    final gen = generation, req = ++requestId;
    emit(previous.copyWith(loadingMore: true, clearFailure: true));
    try {
      final page = await repository.listWorkspaceShifts(
        currentScope.workspaceId,
        previous.query.copyWith(page: previous.page + 1),
      );
      if (!isCurrent(currentScope, gen, req)) return;
      if (page.data.any((i) => i.workspaceId != currentScope.workspaceId)) {
        throw const FormatException('Cross-workspace shift response');
      }
      final ids = previous.records.map((item) => item.id).toSet();
      emit(
        previous.copyWith(
          records: [
            ...previous.records,
            ...page.data.where((i) => ids.add(i.id)),
          ],
          page: page.pagination.page,
          total: page.pagination.total,
          totalPages: page.pagination.totalPages,
          loadingMore: false,
        ),
      );
    } catch (error) {
      if (!isCurrent(currentScope, gen, req)) return;
      emit(
        previous.copyWith(
          loadingMore: false,
          failure: ManagerShiftsHelper.failure(
            error,
            'Unable to load more shifts.',
          ),
        ),
      );
    }
  }
}
