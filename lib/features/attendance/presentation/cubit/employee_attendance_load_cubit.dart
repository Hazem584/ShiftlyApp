import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_attendance_state.dart';

abstract class EmployeeAttendanceLoadCubit
    extends Cubit<EmployeeAttendanceState> {
  EmployeeAttendanceLoadCubit(this.repository)
    : super(const EmployeeAttendanceState());

  final AttendanceRepository repository;
  FeatureSessionScope? scope;
  var generation = 0;
  var requestId = 0;

  void bindSession(FeatureSessionScope? nextScope) {
    final authorized = nextScope?.isEmployee == true ? nextScope : null;
    if (scope == authorized) return;
    scope = authorized;
    generation += 1;
    requestId += 1;
    emit(const EmployeeAttendanceState());
    if (authorized != null) unawaited(load());
  }

  Future<void> load({AttendanceQuery? query, bool refresh = false}) async {
    final activeScope = scope;
    if (activeScope == null) return;
    final gen = generation;
    final reqId = ++requestId;
    final requested = query ?? state.query;
    final prev = state;
    emit(
      refresh && prev.records.isNotEmpty
          ? prev.copyWith(refreshing: true, clearFailure: true)
          : EmployeeAttendanceState(query: requested),
    );
    try {
      final page = await repository.listMyAttendance(
        activeScope.workspaceId,
        requested.copyWith(page: 1),
      );
      if (!isCurrent(activeScope, gen, reqId)) return;
      emit(
        EmployeeAttendanceState(
          initialLoading: false,
          records: page.data
              .where((item) => item.workspaceId == activeScope.workspaceId)
              .toList(growable: false),
          query: requested.copyWith(page: 1),
          page: page.pagination.page,
          totalPages: page.pagination.totalPages,
        ),
      );
    } catch (error) {
      if (!isCurrent(activeScope, gen, reqId)) return;
      final failure = toFailure(error, 'Unable to load attendance history.');
      emit(
        refresh && prev.records.isNotEmpty
            ? prev.copyWith(refreshing: false, failure: failure)
            : EmployeeAttendanceState(
                initialLoading: false,
                query: requested,
                failure: failure,
              ),
      );
    }
  }

  Failure toFailure(Object error, String fallback) =>
      error is ApiException ? error.toFailure() : Failure(message: fallback);
  bool isCurrent(FeatureSessionScope s, int gen, int reqId) =>
      !isClosed && scope == s && generation == gen && requestId == reqId;
}
