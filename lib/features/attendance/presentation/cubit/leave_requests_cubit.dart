import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/attendance/data/leave_request_repository.dart';

enum LeaveMutationResult { success, failure, busy, stale }

class LeaveRequestsState extends Equatable {
  const LeaveRequestsState({
    this.initialLoading = true,
    this.requests = const [],
    this.query = const LeaveRequestQuery(),
    this.page = 1,
    this.totalPages = 0,
    this.refreshing = false,
    this.loadingMore = false,
    this.reviewingIds = const {},
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
  final Set<String> reviewingIds;
  final LeaveRequestRecord? selected;
  final bool detailLoading;
  final Failure? failure;

  bool get hasMore => page < totalPages;
  int get pendingCount => requests
      .where((request) => request.status == LeaveRequestStatus.pending)
      .length;

  LeaveRequestsState copyWith({
    bool? initialLoading,
    List<LeaveRequestRecord>? requests,
    LeaveRequestQuery? query,
    int? page,
    int? totalPages,
    bool? refreshing,
    bool? loadingMore,
    Set<String>? reviewingIds,
    LeaveRequestRecord? selected,
    bool clearSelected = false,
    bool? detailLoading,
    Failure? failure,
    bool clearFailure = false,
  }) => LeaveRequestsState(
    initialLoading: initialLoading ?? this.initialLoading,
    requests: requests ?? this.requests,
    query: query ?? this.query,
    page: page ?? this.page,
    totalPages: totalPages ?? this.totalPages,
    refreshing: refreshing ?? this.refreshing,
    loadingMore: loadingMore ?? this.loadingMore,
    reviewingIds: reviewingIds ?? this.reviewingIds,
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
    reviewingIds,
    selected,
    detailLoading,
    failure,
  ];
}

class LeaveRequestsCubit extends Cubit<LeaveRequestsState> {
  LeaveRequestsCubit(this._repository, {this.onDashboardChanged})
    : super(const LeaveRequestsState());
  final LeaveRequestRepository _repository;
  final void Function()? onDashboardChanged;
  FeatureSessionScope? _scope;
  var _generation = 0;
  var _requestId = 0;

  void bindSession(FeatureSessionScope? scope) {
    final authorized = scope?.isManager == true ? scope : null;
    if (_scope == authorized) return;
    _scope = authorized;
    _generation += 1;
    _requestId += 1;
    emit(const LeaveRequestsState());
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
          : LeaveRequestsState(query: requested),
    );
    try {
      final page = await _repository.listWorkspace(
        scope.workspaceId,
        requested.copyWith(page: 1),
      );
      if (!_current(scope, generation, requestId)) return;
      if (page.data.any((item) => item.workspaceId != scope.workspaceId)) {
        throw const FormatException('Cross-workspace leave response');
      }
      emit(
        LeaveRequestsState(
          initialLoading: false,
          requests: page.data,
          query: requested.copyWith(page: 1),
          page: page.pagination.page,
          totalPages: page.pagination.totalPages,
        ),
      );
    } catch (error) {
      if (!_current(scope, generation, requestId)) return;
      final failure = _failure(error, 'Unable to load leave requests.');
      emit(
        refresh && previous.requests.isNotEmpty
            ? previous.copyWith(refreshing: false, failure: failure)
            : LeaveRequestsState(
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
      final page = await _repository.listWorkspace(
        scope.workspaceId,
        previous.query.copyWith(page: previous.page + 1),
      );
      if (!_current(scope, generation, requestId)) return;
      if (page.data.any((item) => item.workspaceId != scope.workspaceId)) {
        throw const FormatException('Cross-workspace leave response');
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

  Future<LeaveRequestRecord?> loadDetails(String requestId) async {
    final scope = _scope;
    if (scope == null || state.detailLoading) return null;
    final generation = _generation;
    emit(state.copyWith(detailLoading: true, clearFailure: true));
    try {
      final record = await _repository.getWorkspace(
        scope.workspaceId,
        requestId,
      );
      if (!_scopeCurrent(scope, generation) ||
          record.workspaceId != scope.workspaceId) {
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

  Future<LeaveMutationResult> review(
    String requestId,
    LeaveReviewDecision decision, {
    String? rejectionReason,
  }) async {
    final scope = _scope;
    if (scope == null) return LeaveMutationResult.failure;
    if (state.reviewingIds.contains(requestId)) return LeaveMutationResult.busy;
    final reason = rejectionReason?.trim();
    if (decision == LeaveReviewDecision.rejected &&
        (reason == null || reason.isEmpty)) {
      emit(
        state.copyWith(
          failure: const Failure(
            message: 'A rejection reason is required.',
            kind: FailureKind.validation,
          ),
        ),
      );
      return LeaveMutationResult.failure;
    }
    if ((reason?.length ?? 0) > 1000) {
      emit(
        state.copyWith(
          failure: const Failure(
            message: 'Rejection reason is too long.',
            kind: FailureKind.validation,
          ),
        ),
      );
      return LeaveMutationResult.failure;
    }
    final generation = _generation;
    emit(
      state.copyWith(
        reviewingIds: {...state.reviewingIds, requestId},
        clearFailure: true,
      ),
    );
    try {
      final record = await _repository.review(
        scope.workspaceId,
        requestId,
        decision,
        rejectionReason: reason,
      );
      if (!_scopeCurrent(scope, generation)) return LeaveMutationResult.stale;
      final expected = decision == LeaveReviewDecision.approved
          ? LeaveRequestStatus.approved
          : LeaveRequestStatus.rejected;
      if (record.workspaceId != scope.workspaceId ||
          record.id != requestId ||
          record.status != expected) {
        _finishReview(
          requestId,
          failure: const Failure(
            message: 'The server returned an invalid leave review response.',
            kind: FailureKind.server,
          ),
        );
        return LeaveMutationResult.failure;
      }
      _finishReview(requestId, record: record);
      onDashboardChanged?.call();
      return LeaveMutationResult.success;
    } catch (error) {
      if (!_scopeCurrent(scope, generation)) return LeaveMutationResult.stale;
      _finishReview(
        requestId,
        failure: _failure(error, 'Unable to review the leave request.'),
      );
      return LeaveMutationResult.failure;
    }
  }

  void _finishReview(
    String requestId, {
    LeaveRequestRecord? record,
    Failure? failure,
  }) {
    final reviewing = {...state.reviewingIds}..remove(requestId);
    emit(
      state.copyWith(
        reviewingIds: reviewing,
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
