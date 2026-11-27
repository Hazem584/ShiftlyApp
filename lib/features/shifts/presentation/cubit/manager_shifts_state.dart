import 'package:equatable/equatable.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

enum ShiftMutationResult { success, failure, busy, stale }

class ManagerShiftsState extends Equatable {
  const ManagerShiftsState({
    this.initialLoading = true,
    this.records = const [],
    this.query = const ShiftQuery(),
    this.page = 1,
    this.total = 0,
    this.totalPages = 0,
    this.refreshing = false,
    this.loadingMore = false,
    this.creating = false,
    this.updatingId,
    this.cancellingId,
    this.selected,
    this.detailLoading = false,
    this.failure,
  });

  final bool initialLoading, refreshing, loadingMore, creating, detailLoading;
  final List<ShiftRecord> records;
  final ShiftQuery query;
  final int page, total, totalPages;
  final String? updatingId, cancellingId;
  final ShiftRecord? selected;
  final Failure? failure;

  bool get hasMore => page < totalPages;

  ManagerShiftsState copyWith({
    bool? initialLoading,
    List<ShiftRecord>? records,
    ShiftQuery? query,
    int? page,
    int? total,
    int? totalPages,
    bool? refreshing,
    bool? loadingMore,
    bool? creating,
    String? updatingId,
    bool clearUpdating = false,
    String? cancellingId,
    bool clearCancelling = false,
    ShiftRecord? selected,
    bool clearSelected = false,
    bool? detailLoading,
    Failure? failure,
    bool clearFailure = false,
  }) => ManagerShiftsState(
    initialLoading: initialLoading ?? this.initialLoading,
    records: records ?? this.records,
    query: query ?? this.query,
    page: page ?? this.page,
    total: total ?? this.total,
    totalPages: totalPages ?? this.totalPages,
    refreshing: refreshing ?? this.refreshing,
    loadingMore: loadingMore ?? this.loadingMore,
    creating: creating ?? this.creating,
    updatingId: clearUpdating ? null : updatingId ?? this.updatingId,
    cancellingId: clearCancelling ? null : cancellingId ?? this.cancellingId,
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
    total,
    totalPages,
    refreshing,
    loadingMore,
    creating,
    updatingId,
    cancellingId,
    selected,
    detailLoading,
    failure,
  ];
}
