import 'package:equatable/equatable.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';

export 'employee_leave_requests_state_copy.dart';

class EmployeeLeaveRequestsState extends Equatable {
  const EmployeeLeaveRequestsState({
    this.initialLoading = true,
    this.requests = const [],
    this.query = const LeaveRequestQuery(),
    this.page = 1,
    this.totalPages = 0,
    this.refreshing = false,
    this.loadingMore = false,
    this.creating = false,
    this.cancellingIds = const {},
    this.selected,
    this.detailLoading = false,
    this.failure,
  });

  final bool initialLoading;
  final List<LeaveRequestRecord> requests;
  final LeaveRequestQuery query;
  final int page;
  final int totalPages;
  final bool refreshing;
  final bool loadingMore;
  final bool creating;
  final Set<String> cancellingIds;
  final LeaveRequestRecord? selected;
  final bool detailLoading;
  final Failure? failure;

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [
    initialLoading,
    requests,
    query,
    page,
    totalPages,
    refreshing,
    loadingMore,
    creating,
    cancellingIds,
    selected,
    detailLoading,
    failure,
  ];
}
