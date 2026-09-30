import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/data/attendance_calendar_repository.dart';

class AttendanceCalendarState extends Equatable {
  const AttendanceCalendarState({
    this.year,
    this.month,
    this.data,
    this.selectedDate,
    this.loading = false,
    this.refreshing = false,
    this.failure,
  });

  final int? year;
  final int? month;
  final AttendanceCalendarMonth? data;
  final DateTime? selectedDate;
  final bool loading;
  final bool refreshing;
  final Failure? failure;

  bool get hasData => data != null;

  AttendanceCalendarState copyWith({
    int? year,
    int? month,
    AttendanceCalendarMonth? data,
    DateTime? selectedDate,
    bool clearSelectedDate = false,
    bool? loading,
    bool? refreshing,
    Failure? failure,
    bool clearFailure = false,
  }) => AttendanceCalendarState(
    year: year ?? this.year,
    month: month ?? this.month,
    data: data ?? this.data,
    selectedDate: clearSelectedDate ? null : selectedDate ?? this.selectedDate,
    loading: loading ?? this.loading,
    refreshing: refreshing ?? this.refreshing,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [
    year,
    month,
    data,
    selectedDate,
    loading,
    refreshing,
    failure,
  ];
}

class AttendanceCalendarCubit extends Cubit<AttendanceCalendarState> {
  AttendanceCalendarCubit(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(const AttendanceCalendarState());

  final AttendanceCalendarRepository _repository;
  final DateTime Function() _now;
  FeatureSessionScope? _scope;
  var _generation = 0;
  var _requestId = 0;
  bool _requestActive = false;
  bool _followUpRequested = false;
  bool _opened = false;

  void bindSession(FeatureSessionScope? scope) {
    final authorized = scope?.isManager == true ? scope : null;
    if (_scope == authorized) return;
    _scope = authorized;
    _generation += 1;
    _requestId += 1;
    _requestActive = false;
    _followUpRequested = false;
    _opened = false;
    emit(const AttendanceCalendarState());
  }

  Future<void> open() async {
    if (_opened) return;
    _opened = true;
    await load();
  }

  Future<void> load({bool refresh = false}) async {
    final scope = _scope;
    if (scope == null) return;
    if (_requestActive) {
      _followUpRequested = true;
      return;
    }
    final localNow = WorkspaceTime.inWorkspace(_now().toUtc(), scope.timezone);
    final year = state.year ?? localNow.year;
    final month = state.month ?? localNow.month;
    await _performLoad(scope, year, month, refresh: refresh);
  }

  Future<void> previousMonth() => _moveMonth(-1);
  Future<void> nextMonth() => _moveMonth(1);

  Future<void> _moveMonth(int delta) async {
    final scope = _scope;
    if (scope == null) return;
    final localNow = WorkspaceTime.inWorkspace(_now().toUtc(), scope.timezone);
    final current = DateTime(
      state.year ?? localNow.year,
      state.month ?? localNow.month,
    );
    final target = DateTime(current.year, current.month + delta);
    _requestId += 1;
    _requestActive = false;
    _followUpRequested = false;
    emit(
      AttendanceCalendarState(
        year: target.year,
        month: target.month,
        loading: true,
      ),
    );
    await _performLoad(scope, target.year, target.month);
  }

  void selectDate(DateTime date) {
    if (date.year != state.year || date.month != state.month) return;
    emit(
      state.copyWith(selectedDate: DateTime(date.year, date.month, date.day)),
    );
  }

  void invalidate() {
    if (_scope == null || !_opened) return;
    unawaited(load(refresh: state.hasData));
  }

  Future<void> _performLoad(
    FeatureSessionScope scope,
    int year,
    int month, {
    bool refresh = false,
  }) async {
    final generation = _generation;
    final requestId = ++_requestId;
    final previous = state;
    _requestActive = true;
    emit(
      refresh && previous.hasData
          ? previous.copyWith(refreshing: true, clearFailure: true)
          : AttendanceCalendarState(year: year, month: month, loading: true),
    );
    try {
      final data = await _repository.loadMonth(
        workspaceId: scope.workspaceId,
        timezone: scope.timezone,
        year: year,
        month: month,
      );
      if (!_current(scope, generation, requestId)) return;
      if (data.year != year ||
          data.month != month ||
          data.timezone != scope.timezone) {
        throw const FormatException('Invalid calendar response scope');
      }
      emit(
        AttendanceCalendarState(
          year: year,
          month: month,
          data: data,
          selectedDate: previous.year == year && previous.month == month
              ? previous.selectedDate
              : null,
        ),
      );
    } catch (error) {
      if (!_current(scope, generation, requestId)) return;
      final failure = error is ApiException
          ? error.toFailure()
          : const Failure(message: 'Unable to load the attendance calendar.');
      emit(
        refresh && previous.hasData
            ? previous.copyWith(refreshing: false, failure: failure)
            : AttendanceCalendarState(
                year: year,
                month: month,
                failure: failure,
              ),
      );
    } finally {
      if (_currentScope(scope, generation) && _requestId == requestId) {
        _requestActive = false;
        if (_followUpRequested) {
          _followUpRequested = false;
          unawaited(load(refresh: state.hasData));
        }
      }
    }
  }

  bool _current(FeatureSessionScope scope, int generation, int requestId) =>
      _currentScope(scope, generation) && _requestId == requestId;

  bool _currentScope(FeatureSessionScope scope, int generation) =>
      !isClosed && _scope == scope && _generation == generation;
}
