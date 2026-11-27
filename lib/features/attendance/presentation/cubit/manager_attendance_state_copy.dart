import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_state.dart';

extension ManagerAttendanceStateCopy on ManagerAttendanceState {
  ManagerAttendanceState copyWith({
    bool? initialLoading,
    List<AttendanceRecordApi>? records,
    List<AttendanceRecordApi>? pending,
    AttendanceQuery? query,
    int? page,
    int? totalPages,
    int? pendingPage,
    int? pendingTotalPages,
    bool? refreshing,
    bool? loadingMore,
    bool? loadingMorePending,
    Set<String>? reviewingIds,
    AttendanceRecordApi? selected,
    bool clearSelected = false,
    bool? detailLoading,
    Failure? failure,
    bool clearFailure = false,
  }) => ManagerAttendanceState(
    initialLoading: initialLoading ?? this.initialLoading,
    records: records ?? this.records,
    pending: pending ?? this.pending,
    query: query ?? this.query,
    page: page ?? this.page,
    totalPages: totalPages ?? this.totalPages,
    pendingPage: pendingPage ?? this.pendingPage,
    pendingTotalPages: pendingTotalPages ?? this.pendingTotalPages,
    refreshing: refreshing ?? this.refreshing,
    loadingMore: loadingMore ?? this.loadingMore,
    loadingMorePending: loadingMorePending ?? this.loadingMorePending,
    reviewingIds: reviewingIds ?? this.reviewingIds,
    selected: clearSelected ? null : selected ?? this.selected,
    detailLoading: detailLoading ?? this.detailLoading,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}
