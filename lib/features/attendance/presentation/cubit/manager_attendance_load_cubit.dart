import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_helpers.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_state.dart';

abstract class ManagerAttendanceLoadCubit
    extends Cubit<ManagerAttendanceState> {
  ManagerAttendanceLoadCubit(this.repository, {this.onDashboardChanged})
    : super(const ManagerAttendanceState());

  final AttendanceRepository repository;
  final void Function()? onDashboardChanged;
  FeatureSessionScope? scope;
  var generation = 0;
  var requestId = 0;

  void bindSession(FeatureSessionScope? nextScope) {
    final authorized = nextScope?.isManager == true ? nextScope : null;
    if (scope == authorized) return;
    scope = authorized;
    generation += 1;
    requestId += 1;
    emit(const ManagerAttendanceState());
    if (authorized != null) unawaited(load());
  }

  Future<void> load({AttendanceQuery? query, bool refresh = false}) async {
    final activeScope = scope;
    if (activeScope == null) return;
    final gen = generation;
    final reqId = ++requestId;
    final requested = query ?? state.query;
    final prev = state;
    final keepPrev =
        refresh && (prev.records.isNotEmpty || prev.pending.isNotEmpty);
    emit(
      keepPrev
          ? prev.copyWith(refreshing: true, clearFailure: true)
          : ManagerAttendanceState(query: requested),
    );
    try {
      final results = await Future.wait<AttendancePage>([
        repository.listWorkspaceAttendance(
          activeScope.workspaceId,
          requested.copyWith(page: 1),
        ),
        repository.listAttendanceRequests(activeScope.workspaceId),
      ]);
      if (!isCurrent(activeScope, gen, reqId)) return;
      final records = results[0];
      final pending = results[1];
      if ([...records.data, ...pending.data].any(
        (item) => item.workspaceId != activeScope.workspaceId,
      )) {
        throw const FormatException('Cross-workspace attendance response');
      }
      emit(
        ManagerAttendanceState(
          initialLoading: false,
          records: records.data,
          pending: pending.data,
          query: requested.copyWith(page: 1),
          page: records.pagination.page,
          totalPages: records.pagination.totalPages,
          pendingPage: pending.pagination.page,
          pendingTotalPages: pending.pagination.totalPages,
        ),
      );
    } catch (error) {
      if (!isCurrent(activeScope, gen, reqId)) return;
      final failure = attendanceFailure(error, 'Unable to load attendance.');
      emit(
        keepPrev
            ? prev.copyWith(refreshing: false, failure: failure)
            : ManagerAttendanceState(
                initialLoading: false,
                query: requested,
                failure: failure,
              ),
      );
    }
  }

  bool isCurrent(FeatureSessionScope s, int gen, int reqId) =>
      isScopeCurrent(s, gen) && requestId == reqId;
  bool isScopeCurrent(FeatureSessionScope s, int gen) =>
      !isClosed && scope == s && generation == gen;
}
