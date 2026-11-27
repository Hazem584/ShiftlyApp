import 'package:shiftly/features/attendance/presentation/cubit/employee_attendance_load_cubit.dart';

export 'employee_attendance_state.dart';

class EmployeeAttendanceCubit extends EmployeeAttendanceLoadCubit {
  EmployeeAttendanceCubit(super.repository);

  Future<void> loadMore() async {
    final activeScope = scope;
    final prev = state;
    if (activeScope == null || prev.loadingMore || !prev.hasMore) return;
    final gen = generation;
    final reqId = ++requestId;
    emit(prev.copyWith(loadingMore: true, clearFailure: true));
    try {
      final page = await repository.listMyAttendance(
        activeScope.workspaceId,
        prev.query.copyWith(page: prev.page + 1),
      );
      if (!isCurrent(activeScope, gen, reqId)) return;
      final ids = prev.records.map((item) => item.id).toSet();
      emit(
        prev.copyWith(
          records: [
            ...prev.records,
            ...page.data.where(
              (item) =>
                  item.workspaceId == activeScope.workspaceId &&
                  ids.add(item.id),
            ),
          ],
          page: page.pagination.page,
          totalPages: page.pagination.totalPages,
          loadingMore: false,
        ),
      );
    } catch (error) {
      if (!isCurrent(activeScope, gen, reqId)) return;
      emit(
        prev.copyWith(
          loadingMore: false,
          failure: toFailure(error, 'Unable to load more attendance.'),
        ),
      );
    }
  }
}
