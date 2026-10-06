part of '../../employee_shifts_cubit.dart';

class EmployeeShiftsState extends Equatable {
  const EmployeeShiftsState({
    this.initialLoading = true,
    this.records = const [],
    this.query = const ShiftQuery(),
    this.page = 1,
    this.totalPages = 0,
    this.refreshing = false,
    this.loadingMore = false,
    this.clockingInIds = const {},
    this.clockingOutIds = const {},
    this.selected,
    this.detailLoading = false,
    this.failure,
  });

  final bool initialLoading;
  final List<ShiftRecord> records;
  final ShiftQuery query;
  final int page;
  final int totalPages;
  final bool refreshing;
  final bool loadingMore;
  final Set<String> clockingInIds;
  final Set<String> clockingOutIds;
  final ShiftRecord? selected;
  final bool detailLoading;
  final Failure? failure;

  bool get hasMore => page < totalPages;

  EmployeeShiftsState copyWith({
    bool? initialLoading,
    List<ShiftRecord>? records,
    ShiftQuery? query,
    int? page,
    int? totalPages,
    bool? refreshing,
    bool? loadingMore,
    Set<String>? clockingInIds,
    Set<String>? clockingOutIds,
    ShiftRecord? selected,
    bool clearSelected = false,
    bool? detailLoading,
    Failure? failure,
    bool clearFailure = false,
  }) => EmployeeShiftsState(
    initialLoading: initialLoading ?? this.initialLoading,
    records: records ?? this.records,
    query: query ?? this.query,
    page: page ?? this.page,
    totalPages: totalPages ?? this.totalPages,
    refreshing: refreshing ?? this.refreshing,
    loadingMore: loadingMore ?? this.loadingMore,
    clockingInIds: clockingInIds ?? this.clockingInIds,
    clockingOutIds: clockingOutIds ?? this.clockingOutIds,
    selected: clearSelected ? null : selected ?? this.selected,
    detailLoading: detailLoading ?? this.detailLoading,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [
    initialLoading,
    records,
    query,
    page,
    totalPages,
    refreshing,
    loadingMore,
    clockingInIds,
    clockingOutIds,
    selected,
    detailLoading,
    failure,
  ];
}
