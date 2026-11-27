import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_leave_requests_load_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_leave_requests_state.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_helpers.dart';

abstract class EmployeeLeaveRequestsPageCubit
    extends EmployeeLeaveRequestsLoadCubit {
  EmployeeLeaveRequestsPageCubit(super.repository, {super.onDashboardChanged});

  Future<void> loadMore() async {
    final activeScope = scope;
    final prev = state;
    if (activeScope == null || prev.loadingMore || !prev.hasMore) return;
    final gen = generation;
    final reqId = ++requestId;
    emit(prev.copyWith(loadingMore: true, clearFailure: true));
    try {
      final page = await repository.listMine(
        activeScope.workspaceId,
        prev.query.copyWith(page: prev.page + 1),
      );
      if (!isCurrent(activeScope, gen, reqId)) return;
      if (hasInvalidMineRecords(page.data, activeScope)) {
        throw const FormatException('Invalid employee leave response');
      }
      final ids = prev.requests.map((item) => item.id).toSet();
      emit(
        prev.copyWith(
          requests: [...prev.requests, ...page.data.where((i) => ids.add(i.id))],
          page: page.pagination.page,
          totalPages: page.pagination.totalPages,
          loadingMore: false,
        ),
      );
    } catch (error) {
      if (!isCurrent(activeScope, gen, reqId)) return;
      final failure = leaveFailure(
        error,
        'Unable to load more leave requests.',
      );
      emit(prev.copyWith(loadingMore: false, failure: failure));
    }
  }

  Future<LeaveRequestRecord?> loadDetails(String reqIdStr) async {
    final activeScope = scope;
    if (activeScope == null || state.detailLoading) return null;
    final gen = generation;
    emit(state.copyWith(detailLoading: true, clearFailure: true));
    try {
      final record = await repository.getMine(reqIdStr);
      if (!isScopeCurrent(activeScope, gen) ||
          hasInvalidMineRecords([record], activeScope)) {
        if (isScopeCurrent(activeScope, gen)) {
          emit(state.copyWith(detailLoading: false));
        }
        return null;
      }
      emit(state.copyWith(selected: record, detailLoading: false));
      return record;
    } catch (error) {
      if (!isScopeCurrent(activeScope, gen)) return null;
      final failure = leaveFailure(
        error,
        'Unable to load leave request details.',
      );
      emit(state.copyWith(detailLoading: false, failure: failure));
      return null;
    }
  }
}
