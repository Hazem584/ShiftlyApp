import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_helpers.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_load_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_state.dart';

abstract class ManagerAttendancePageCubit extends ManagerAttendanceLoadCubit {
  ManagerAttendancePageCubit(super.repository, {super.onDashboardChanged});

  Future<void> loadMore() async {
    final activeScope = scope;
    final prev = state;
    if (activeScope == null || prev.loadingMore || !prev.hasMore) return;
    final gen = generation;
    final reqId = ++requestId;
    emit(prev.copyWith(loadingMore: true, clearFailure: true));
    try {
      final page = await repository.listWorkspaceAttendance(
        activeScope.workspaceId,
        prev.query.copyWith(page: prev.page + 1),
      );
      if (!isCurrent(activeScope, gen, reqId)) return;
      if (page.data.any((i) => i.workspaceId != activeScope.workspaceId)) {
        throw const FormatException('Cross-workspace attendance response');
      }
      final ids = prev.records.map((item) => item.id).toSet();
      emit(
        prev.copyWith(
          records: [...prev.records, ...page.data.where((i) => ids.add(i.id))],
          page: page.pagination.page,
          totalPages: page.pagination.totalPages,
          loadingMore: false,
        ),
      );
    } catch (error) {
      if (!isCurrent(activeScope, gen, reqId)) return;
      final failure = attendanceFailure(
        error,
        'Unable to load more attendance.',
      );
      emit(prev.copyWith(loadingMore: false, failure: failure));
    }
  }

  Future<void> loadMorePending() async {
    final activeScope = scope;
    final prev = state;
    if (activeScope == null ||
        prev.loadingMorePending ||
        !prev.hasMorePending) {
      return;
    }
    final gen = generation;
    emit(prev.copyWith(loadingMorePending: true, clearFailure: true));
    try {
      final page = await repository.listAttendanceRequests(
        activeScope.workspaceId,
        page: prev.pendingPage + 1,
      );
      if (!isScopeCurrent(activeScope, gen)) return;
      if (page.data.any((i) => i.workspaceId != activeScope.workspaceId)) {
        throw const FormatException('Cross-workspace attendance response');
      }
      final ids = prev.pending.map((item) => item.id).toSet();
      emit(
        prev.copyWith(
          pending: [...prev.pending, ...page.data.where((i) => ids.add(i.id))],
          pendingPage: page.pagination.page,
          pendingTotalPages: page.pagination.totalPages,
          loadingMorePending: false,
        ),
      );
    } catch (error) {
      if (!isScopeCurrent(activeScope, gen)) return;
      final failure = attendanceFailure(error, 'Unable to load more requests.');
      emit(prev.copyWith(loadingMorePending: false, failure: failure));
    }
  }
}
