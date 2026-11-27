import 'package:equatable/equatable.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';

export 'manager_attendance_state_copy.dart';

enum AttendanceMutationResult { success, failure, busy, stale }

class ManagerAttendanceState extends Equatable {
  const ManagerAttendanceState({
    this.initialLoading = true,
    this.records = const [],
    this.pending = const [],
    this.query = const AttendanceQuery(),
    this.page = 1,
    this.totalPages = 0,
    this.pendingPage = 1,
    this.pendingTotalPages = 0,
    this.refreshing = false,
    this.loadingMore = false,
    this.loadingMorePending = false,
    this.reviewingIds = const {},
    this.selected,
    this.detailLoading = false,
    this.failure,
  });

  final bool initialLoading;
  final List<AttendanceRecordApi> records;
  final List<AttendanceRecordApi> pending;
  final AttendanceQuery query;
  final int page;
  final int totalPages;
  final int pendingPage;
  final int pendingTotalPages;
  final bool refreshing;
  final bool loadingMore;
  final bool loadingMorePending;
  final Set<String> reviewingIds;
  final AttendanceRecordApi? selected;
  final bool detailLoading;
  final Failure? failure;

  bool get hasMore => page < totalPages;
  bool get hasMorePending => pendingPage < pendingTotalPages;

  @override
  List<Object?> get props => [
    initialLoading,
    records,
    pending,
    query,
    page,
    totalPages,
    pendingPage,
    pendingTotalPages,
    refreshing,
    loadingMore,
    loadingMorePending,
    reviewingIds,
    selected,
    detailLoading,
    failure,
  ];
}
