import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_leave_requests_state.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_helpers.dart';

abstract class EmployeeLeaveRequestsLoadCubit
    extends Cubit<EmployeeLeaveRequestsState> {
  EmployeeLeaveRequestsLoadCubit(this.repository, {this.onDashboardChanged})
    : super(const EmployeeLeaveRequestsState());

  final LeaveRequestRepository repository;
  final void Function()? onDashboardChanged;
  FeatureSessionScope? scope;
  var generation = 0;
  var requestId = 0;

  void bindSession(FeatureSessionScope? nextScope) {
    final authorized = nextScope?.isEmployee == true ? nextScope : null;
    if (scope == authorized) return;
    scope = authorized;
    generation += 1;
    requestId += 1;
    emit(const EmployeeLeaveRequestsState());
    if (authorized != null) unawaited(load());
  }

  Future<void> load({LeaveRequestQuery? query, bool refresh = false}) async {
    final activeScope = scope;
    if (activeScope == null) return;
    final gen = generation;
    final reqId = ++requestId;
    final requested = query ?? state.query;
    final prev = state;
    emit(
      refresh && prev.requests.isNotEmpty
          ? prev.copyWith(refreshing: true, clearFailure: true)
          : EmployeeLeaveRequestsState(query: requested),
    );
    try {
      final page = await repository.listMine(
        activeScope.workspaceId,
        requested.copyWith(page: 1),
      );
      if (!isCurrent(activeScope, gen, reqId)) return;
      if (hasInvalidMineRecords(page.data, activeScope)) {
        throw const FormatException('Invalid employee leave response');
      }
      emit(
        EmployeeLeaveRequestsState(
          initialLoading: false,
          requests: page.data,
          query: requested.copyWith(page: 1),
          page: page.pagination.page,
          totalPages: page.pagination.totalPages,
        ),
      );
    } catch (error) {
      if (!isCurrent(activeScope, gen, reqId)) return;
      final failure = leaveFailure(
        error,
        'Unable to load your leave requests.',
      );
      emit(
        refresh && prev.requests.isNotEmpty
            ? prev.copyWith(refreshing: false, failure: failure)
            : EmployeeLeaveRequestsState(
                initialLoading: false,
                query: requested,
                failure: failure,
              ),
      );
    }
  }

  bool hasInvalidMineRecords(
    List<LeaveRequestRecord> items,
    FeatureSessionScope s,
  ) => items.any(
    (i) =>
        i.workspaceId != s.workspaceId ||
        i.employeeMembershipId != s.membershipId,
  );

  bool isCurrent(FeatureSessionScope s, int gen, int reqId) =>
      isScopeCurrent(s, gen) && requestId == reqId;
  bool isScopeCurrent(FeatureSessionScope s, int gen) =>
      !isClosed && scope == s && generation == gen;
}
