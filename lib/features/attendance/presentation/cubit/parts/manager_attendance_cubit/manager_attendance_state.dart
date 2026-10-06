part of '../../manager_attendance_cubit.dart';

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
