import 'package:equatable/equatable.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

enum ClockMutationResult { success, failure, busy, stale }

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

  final bool initialLoading, refreshing, loadingMore, detailLoading;
  final List<ShiftRecord> records;
  final ShiftQuery query;
  final int page, totalPages;
  final Set<String> clockingInIds, clockingOutIds;
  final ShiftRecord? selected;
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
