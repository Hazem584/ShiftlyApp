import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_leave_requests_state.dart';

extension EmployeeLeaveRequestsStateCopy on EmployeeLeaveRequestsState {
  EmployeeLeaveRequestsState copyWith({
    bool? initialLoading,
    List<LeaveRequestRecord>? requests,
    LeaveRequestQuery? query,
    int? page,
    int? totalPages,
    bool? refreshing,
    bool? loadingMore,
    bool? creating,
    Set<String>? cancellingIds,
    LeaveRequestRecord? selected,
    bool clearSelected = false,
    bool? detailLoading,
    Failure? failure,
    bool clearFailure = false,
  }) => EmployeeLeaveRequestsState(
    initialLoading: initialLoading ?? this.initialLoading,
    requests: requests ?? this.requests,
    query: query ?? this.query,
    page: page ?? this.page,
    totalPages: totalPages ?? this.totalPages,
    refreshing: refreshing ?? this.refreshing,
    loadingMore: loadingMore ?? this.loadingMore,
    creating: creating ?? this.creating,
    cancellingIds: cancellingIds ?? this.cancellingIds,
    selected: clearSelected ? null : selected ?? this.selected,
    detailLoading: detailLoading ?? this.detailLoading,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}
