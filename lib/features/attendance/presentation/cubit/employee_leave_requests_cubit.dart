import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/attendance/data/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';

class EmployeeLeaveRequestsState extends Equatable {
  const EmployeeLeaveRequestsState({
    this.initialLoading = true,
    this.requests = const [],
    this.query = const LeaveRequestQuery(),
    this.page = 1,
    this.totalPages = 0,
    this.refreshing = false,
    this.loadingMore = false,
    this.creating = false,
    this.cancellingIds = const {},
    this.selected,
    this.detailLoading = false,
    this.failure,
  });

  final bool initialLoading;
  final List<LeaveRequestRecord> requests;
  final LeaveRequestQuery query;
  final int page;
  final int totalPages;
  final bool refreshing;
  final bool loadingMore;
  final bool creating;
  final Set<String> cancellingIds;
  final LeaveRequestRecord? selected;
  final bool detailLoading;
  final Failure? failure;

  bool get hasMore => page < totalPages;

  EmployeeLeaveRequestsState copyWith({
    bool? initialLoading,
    List<LeaveRequestRecord>? requests,
    LeaveRequestQuery? query,
    int? page,
    int? totalPages,
    bool? refreshing,
    bool? loadingMore,
    bool? creating,
    Set<String>? cancellingIds,
    LeaveRequestRecord? selected,
    bool clearSelected = false,
    bool? detailLoading,
    Failure? failure,
    bool clearFailure = false,
  }) => EmployeeLeaveRequestsState(
    initialLoading: initialLoading ?? this.initialLoading,
    requests: requests ?? this.requests,
    query: query ?? this.query,
    page: page ?? this.page,
    totalPages: totalPages ?? this.totalPages,
    refreshing: refreshing ?? this.refreshing,
    loadingMore: loadingMore ?? this.loadingMore,
    creating: creating ?? this.creating,
    cancellingIds: cancellingIds ?? this.cancellingIds,
    selected: clearSelected ? null : selected ?? this.selected,
    detailLoading: detailLoading ?? this.detailLoading,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [
    initialLoading,
    requests,
    query,
    page,
    totalPages,
    refreshing,
    loadingMore,
    creating,
    cancellingIds,
    selected,
    detailLoading,
    failure,
  ];
}

class EmployeeLeaveRequestsCubit extends Cubit<EmployeeLeaveRequestsState> {
  EmployeeLeaveRequestsCubit(this._repository, {this.onDashboardChanged})
    : super(const EmployeeLeaveRequestsState());
  final LeaveRequestRepository _repository;
  final void Function()? onDashboardChanged;
  FeatureSessionScope? _scope;
  var _generation = 0;
  var _requestId = 0;

  void bindSession(FeatureSessionScope? scope) {
    final authorized = scope?.isEmployee == true ? scope : null;
    if (_scope == authorized) return;
    _scope = authorized;
    _generation += 1;
    _requestId += 1;
    emit(const EmployeeLeaveRequestsState());
    if (authorized != null) unawaited(load());
  }

  Future<void> load({LeaveRequestQuery? query, bool refresh = false}) async {
    final scope = _scope;
    if (scope == null) return;
    final generation = _generation;
    final requestId = ++_requestId;
    final requested = query ?? state.query;
    final previous = state;
    emit(
      refresh && previous.requests.isNotEmpty
          ? previous.copyWith(refreshing: true, clearFailure: true)
          : EmployeeLeaveRequestsState(query: requested),
    );
    try {
      final page = await _repository.listMine(
        scope.workspaceId,
        requested.copyWith(page: 1),
      );
      if (!_current(scope, generation, requestId)) return;
      if (page.data.any(
        (item) =>
            item.workspaceId != scope.workspaceId ||
            item.employeeMembershipId != scope.membershipId,
      )) {
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
      if (!_current(scope, generation, requestId)) return;
      final failure = _failure(error, 'Unable to load your leave requests.');
      emit(
        refresh && previous.requests.isNotEmpty
            ? previous.copyWith(refreshing: false, failure: failure)
            : EmployeeLeaveRequestsState(
                initialLoading: false,
                query: requested,
                failure: failure,
              ),
      );
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
      final page = await _repository.listMine(
        scope.workspaceId,
        previous.query.copyWith(page: previous.page + 1),
      );
      if (!_current(scope, generation, requestId)) return;
      if (page.data.any(
        (item) =>
            item.workspaceId != scope.workspaceId ||
            item.employeeMembershipId != scope.membershipId,
      )) {
        throw const FormatException('Invalid employee leave response');
      }
      final ids = previous.requests.map((item) => item.id).toSet();
      emit(
        previous.copyWith(
          requests: [
            ...previous.requests,
            ...page.data.where((item) => ids.add(item.id)),
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
          failure: _failure(error, 'Unable to load more leave requests.'),
        ),
      );
    }
  }

  Future<LeaveMutationResult> create(CreateLeaveRequestInput input) async {
    final scope = _scope;
    if (scope == null) return LeaveMutationResult.failure;
    if (state.creating) return LeaveMutationResult.busy;
    final validation = validate(input);
    if (validation != null) {
      emit(state.copyWith(failure: validation));
      return LeaveMutationResult.failure;
    }
    final generation = _generation;
    emit(state.copyWith(creating: true, clearFailure: true));
    try {
      final record = await _repository.create(scope.workspaceId, input);
      if (!_scopeCurrent(scope, generation)) return LeaveMutationResult.stale;
      if (record.workspaceId != scope.workspaceId ||
          record.employeeMembershipId != scope.membershipId ||
          record.status != LeaveRequestStatus.pending) {
        emit(
          state.copyWith(
            creating: false,
            failure: const Failure(
              message: 'The server returned an invalid leave request.',
              kind: FailureKind.server,
            ),
          ),
        );
        return LeaveMutationResult.failure;
      }
      emit(
        state.copyWith(
          requests: [
            record,
            ...state.requests.where((item) => item.id != record.id),
          ],
          creating: false,
        ),
      );
      onDashboardChanged?.call();
      return LeaveMutationResult.success;
    } catch (error) {
      if (!_scopeCurrent(scope, generation)) return LeaveMutationResult.stale;
      emit(
        state.copyWith(
          creating: false,
          failure: _failure(error, 'Unable to create the leave request.'),
        ),
      );
      return LeaveMutationResult.failure;
    }
  }

  Future<LeaveMutationResult> cancel(String requestId) async {
    final scope = _scope;
    if (scope == null) return LeaveMutationResult.failure;
    if (state.cancellingIds.contains(requestId)) {
      return LeaveMutationResult.busy;
    }
    final generation = _generation;
    emit(
      state.copyWith(
        cancellingIds: {...state.cancellingIds, requestId},
        clearFailure: true,
      ),
    );
    try {
      final record = await _repository.cancelMine(requestId);
      if (!_scopeCurrent(scope, generation)) return LeaveMutationResult.stale;
      if (record.id != requestId ||
          record.workspaceId != scope.workspaceId ||
          record.employeeMembershipId != scope.membershipId ||
          record.status != LeaveRequestStatus.cancelled) {
        _finishCancel(
          requestId,
          failure: const Failure(
            message: 'The server returned an invalid cancellation response.',
            kind: FailureKind.server,
          ),
        );
        return LeaveMutationResult.failure;
      }
      _finishCancel(requestId, record: record);
      onDashboardChanged?.call();
      return LeaveMutationResult.success;
    } catch (error) {
      if (!_scopeCurrent(scope, generation)) return LeaveMutationResult.stale;
      _finishCancel(
        requestId,
        failure: _failure(error, 'Unable to cancel the leave request.'),
      );
      return LeaveMutationResult.failure;
    }
  }

  Future<LeaveRequestRecord?> loadDetails(String requestId) async {
    final scope = _scope;
    if (scope == null || state.detailLoading) return null;
    final generation = _generation;
    emit(state.copyWith(detailLoading: true, clearFailure: true));
    try {
      final record = await _repository.getMine(requestId);
      if (!_scopeCurrent(scope, generation) ||
          record.workspaceId != scope.workspaceId ||
          record.employeeMembershipId != scope.membershipId) {
        if (_scopeCurrent(scope, generation)) {
          emit(state.copyWith(detailLoading: false));
        }
        return null;
      }
      emit(state.copyWith(selected: record, detailLoading: false));
      return record;
    } catch (error) {
      if (!_scopeCurrent(scope, generation)) return null;
      emit(
        state.copyWith(
          detailLoading: false,
          failure: _failure(error, 'Unable to load leave request details.'),
        ),
      );
      return null;
    }
  }

  static Failure? validate(CreateLeaveRequestInput input) {
    if (input.type == LeaveRequestType.unknown) {
      return const Failure(
        message: 'Select a valid leave type.',
        kind: FailureKind.validation,
      );
    }
    if (!input.endsAt.isAfter(input.startsAt)) {
      return const Failure(
        message: 'Leave end must be after its start.',
        kind: FailureKind.validation,
      );
    }
    if (!input.startsAt.isAfter(DateTime.now().toUtc())) {
      return const Failure(
        message: 'Leave must start in the future.',
        kind: FailureKind.validation,
      );
    }
    if (input.endsAt.difference(input.startsAt) > const Duration(days: 365)) {
      return const Failure(
        message: 'Leave cannot be longer than 365 days.',
        kind: FailureKind.validation,
      );
    }
    final reason = input.reason.trim();
    if (reason.isEmpty || reason.length > 1000) {
      return const Failure(
        message: 'Enter a reason of up to 1000 characters.',
        kind: FailureKind.validation,
      );
    }
    return null;
  }

  void _finishCancel(
    String requestId, {
    LeaveRequestRecord? record,
    Failure? failure,
  }) {
    final cancelling = {...state.cancellingIds}..remove(requestId);
    emit(
      state.copyWith(
        cancellingIds: cancelling,
        requests: record == null
            ? state.requests
            : state.requests
                  .map((item) => item.id == requestId ? record : item)
                  .toList(growable: false),
        selected: state.selected?.id == requestId ? record : state.selected,
        failure: failure,
      ),
    );
  }

  Failure _failure(Object error, String fallback) =>
      error is ApiException ? error.toFailure() : Failure(message: fallback);
  bool _current(FeatureSessionScope scope, int generation, int requestId) =>
      _scopeCurrent(scope, generation) && _requestId == requestId;
  bool _scopeCurrent(FeatureSessionScope scope, int generation) =>
      !isClosed && _scope == scope && _generation == generation;
}
