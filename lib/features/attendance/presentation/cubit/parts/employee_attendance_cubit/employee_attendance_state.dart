part of '../../employee_attendance_cubit.dart';

class EmployeeAttendanceState extends Equatable {
  const EmployeeAttendanceState({
    this.initialLoading = true,
    this.records = const [],
    this.query = const AttendanceQuery(),
    this.page = 1,
    this.totalPages = 0,
    this.refreshing = false,
    this.loadingMore = false,
    this.failure,
  });

  final bool initialLoading;
  final List<AttendanceRecordApi> records;
  final AttendanceQuery query;
  final int page;
  final int totalPages;
  final bool refreshing;
  final bool loadingMore;
  final Failure? failure;

  bool get hasMore => page < totalPages;

  EmployeeAttendanceState copyWith({
    bool? initialLoading,
    List<AttendanceRecordApi>? records,
    AttendanceQuery? query,
    int? page,
    int? totalPages,
    bool? refreshing,
    bool? loadingMore,
    Failure? failure,
    bool clearFailure = false,
  }) => EmployeeAttendanceState(
    initialLoading: initialLoading ?? this.initialLoading,
    records: records ?? this.records,
    query: query ?? this.query,
    page: page ?? this.page,
    totalPages: totalPages ?? this.totalPages,
    refreshing: refreshing ?? this.refreshing,
    loadingMore: loadingMore ?? this.loadingMore,
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
    failure,
  ];
}
