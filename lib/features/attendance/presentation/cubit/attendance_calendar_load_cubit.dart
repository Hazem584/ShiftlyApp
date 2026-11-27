import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_calendar_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/attendance_calendar_cubit_state.dart';

abstract class AttendanceCalendarLoadCubit
    extends Cubit<AttendanceCalendarState> {
  AttendanceCalendarLoadCubit(
    this.repository, {
    DateTime Function()? now,
    this.employee = false,
  }) : nowFn = now ?? DateTime.now,
       super(const AttendanceCalendarState());

  final AttendanceCalendarRepository repository;
  final bool employee;
  final DateTime Function() nowFn;
  FeatureSessionScope? scope;
  var generation = 0;
  var requestId = 0;
  bool requestActive = false;
  bool followUpRequested = false;
  bool opened = false;
  Timer? deadline;

  @override
  Future<void> close() {
    deadline?.cancel();
    return super.close();
  }

  Future<void> load({bool refresh = false});

  Future<void> performLoad(
    FeatureSessionScope activeScope,
    int year,
    int month, {
    bool refresh = false,
  }) async {
    final gen = generation;
    final reqId = ++requestId;
    final prev = state;
    requestActive = true;
    emit(
      refresh && prev.hasData
          ? prev.copyWith(refreshing: true, clearFailure: true)
          : AttendanceCalendarState(year: year, month: month, loading: true),
    );
    try {
      final data = await repository.loadMonth(
        workspaceId: activeScope.workspaceId,
        timezone: activeScope.timezone,
        year: year,
        month: month,
      );
      if (!isCurrent(activeScope, gen, reqId)) return;
      if (data.year != year ||
          data.month != month ||
          data.timezone != activeScope.timezone) {
        throw const FormatException('Invalid calendar response scope');
      }
      _scheduleDeadline(data);
      final keepSelected = prev.year == year && prev.month == month;
      emit(
        AttendanceCalendarState(
          year: year,
          month: month,
          data: data,
          selectedDate: keepSelected ? prev.selectedDate : null,
        ),
      );
    } catch (error) {
      if (!isCurrent(activeScope, gen, reqId)) return;
      final failure = error is ApiException
          ? error.toFailure()
          : const Failure(message: 'Unable to load the attendance calendar.');
      emit(
        refresh && prev.hasData
            ? prev.copyWith(refreshing: false, failure: failure)
            : AttendanceCalendarState(
                year: year,
                month: month,
                failure: failure,
              ),
      );
    } finally {
      if (isCurrentScope(activeScope, gen) && requestId == reqId) {
        requestActive = false;
        if (followUpRequested) {
          followUpRequested = false;
          unawaited(load(refresh: state.hasData));
        }
      }
    }
  }

  void _scheduleDeadline(AttendanceCalendarMonth data) {
    deadline?.cancel();
    final due = data.nextRefreshAt;
    if (due == null) return;
    final delay =
        due.difference(data.evaluatedAt ?? nowFn().toUtc()) +
        const Duration(seconds: 1);
    deadline = Timer(
      delay.isNegative ? const Duration(seconds: 1) : delay,
      () => load(refresh: true),
    );
  }

  bool isCurrent(FeatureSessionScope s, int gen, int reqId) =>
      isCurrentScope(s, gen) && requestId == reqId;
  bool isCurrentScope(FeatureSessionScope s, int gen) =>
      !isClosed && scope == s && generation == gen;
}
