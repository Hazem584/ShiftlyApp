part of '../../leave_requests_cubit.dart';

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

  LeaveRequestsState copyWith({
    bool? initialLoading,
    List<LeaveRequestRecord>? requests,
    LeaveRequestQuery? query,
    int? page,
    int? totalPages,
    bool? refreshing,
    bool? loadingMore,
    Set<String>? reviewingIds,
    LeaveRequestRecord? selected,
    bool clearSelected = false,
    bool? detailLoading,
    Failure? failure,
    bool clearFailure = false,
  }) => LeaveRequestsState(
    initialLoading: initialLoading ?? this.initialLoading,
    requests: requests ?? this.requests,
    query: query ?? this.query,
    page: page ?? this.page,
    totalPages: totalPages ?? this.totalPages,
    refreshing: refreshing ?? this.refreshing,
    loadingMore: loadingMore ?? this.loadingMore,
    reviewingIds: reviewingIds ?? this.reviewingIds,
    selected: clearSelected ? null : selected ?? this.selected,
    detailLoading: detailLoading ?? this.detailLoading,
    failure: clearFailure ? null : failure ?? this.failure,
  );

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
