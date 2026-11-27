import 'package:equatable/equatable.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';

export 'leave_requests_state_copy.dart';

enum LeaveMutationResult { success, failure, busy, stale }

class LeaveRequestsState extends Equatable {
  const LeaveRequestsState({
    this.initialLoading = true,
    this.requests = const [],
    this.query = const LeaveRequestQuery(),
    this.page = 1,
    this.totalPages = 0,
    this.refreshing = false,
    this.loadingMore = false,
    this.reviewingIds = const {},
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
  final Set<String> reviewingIds;
  final LeaveRequestRecord? selected;
  final bool detailLoading;
  final Failure? failure;

  bool get hasMore => page < totalPages;
  int get pendingCount => requests
      .where((request) => request.status == LeaveRequestStatus.pending)
      .length;

  @override
  List<Object?> get props => [
    initialLoading,
    requests,
    query,
    page,
    totalPages,
    refreshing,
    loadingMore,
    reviewingIds,
    selected,
    detailLoading,
    failure,
  ];
}
