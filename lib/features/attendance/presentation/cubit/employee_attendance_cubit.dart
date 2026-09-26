import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/attendance/data/attendance_repository.dart';

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

class EmployeeAttendanceCubit extends Cubit<EmployeeAttendanceState> {
  EmployeeAttendanceCubit(this._repository)
    : super(const EmployeeAttendanceState());

  final AttendanceRepository _repository;
  FeatureSessionScope? _scope;
  var _generation = 0;
  var _requestId = 0;

  void bindSession(FeatureSessionScope? scope) {
    final authorized = scope?.isEmployee == true ? scope : null;
    if (_scope == authorized) return;
    _scope = authorized;
    _generation += 1;
    _requestId += 1;
    emit(const EmployeeAttendanceState());
    if (authorized != null) unawaited(load());
  }

  Future<void> load({AttendanceQuery? query, bool refresh = false}) async {
    final scope = _scope;
    if (scope == null) return;
    final generation = _generation;
    final requestId = ++_requestId;
    final requested = query ?? state.query;
    final previous = state;
    emit(
      refresh && previous.records.isNotEmpty
          ? previous.copyWith(refreshing: true, clearFailure: true)
          : EmployeeAttendanceState(query: requested),
    );
    try {
      final page = await _repository.listMyAttendance(
        requested.copyWith(page: 1),
      );
      if (!_current(scope, generation, requestId)) return;
      emit(
        EmployeeAttendanceState(
          initialLoading: false,
          records: page.data
              .where((item) => item.workspaceId == scope.workspaceId)
              .toList(growable: false),
          query: requested.copyWith(page: 1),
          page: page.pagination.page,
          totalPages: page.pagination.totalPages,
        ),
      );
    } catch (error) {
      if (!_current(scope, generation, requestId)) return;
      final failure = _failure(error, 'Unable to load attendance history.');
      if (refresh && previous.records.isNotEmpty) {
        emit(previous.copyWith(refreshing: false, failure: failure));
      } else {
        emit(
          EmployeeAttendanceState(
            initialLoading: false,
            query: requested,
            failure: failure,
          ),
        );
      }
    }
  }

  Future<void> loadMore() async {
    final scope = _scope;
    final previous = state;
    if (scope == null || previous.loadingMore || !previous.hasMore) return;
    final generation = _generation;
    final requestId = ++_requestId;
    emit(previous.copyWith(loadingMore: true, clearFailure: true));
    try {
      final page = await _repository.listMyAttendance(
        previous.query.copyWith(page: previous.page + 1),
      );
      if (!_current(scope, generation, requestId)) return;
      final ids = previous.records.map((item) => item.id).toSet();
      emit(
        previous.copyWith(
          records: [
            ...previous.records,
            ...page.data.where(
              (item) =>
                  item.workspaceId == scope.workspaceId && ids.add(item.id),
            ),
          ],
          page: page.pagination.page,
          totalPages: page.pagination.totalPages,
          loadingMore: false,
        ),
      );
    } catch (error) {
      if (!_current(scope, generation, requestId)) return;
      emit(
        previous.copyWith(
          loadingMore: false,
          failure: _failure(error, 'Unable to load more attendance.'),
        ),
      );
    }
  }

  Failure _failure(Object error, String fallback) =>
      error is ApiException ? error.toFailure() : Failure(message: fallback);
  bool _current(FeatureSessionScope scope, int generation, int requestId) =>
      !isClosed &&
      _scope == scope &&
      _generation == generation &&
      _requestId == requestId;
}
