part of '../../manager_attendance_cubit.dart';

class ManagerAttendanceCubit extends Cubit<ManagerAttendanceState> {
  ManagerAttendanceCubit(this._repository, {this.onDashboardChanged})
    : super(const ManagerAttendanceState());

  final AttendanceRepository _repository;
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
    emit(const ManagerAttendanceState());
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
      refresh && (previous.records.isNotEmpty || previous.pending.isNotEmpty)
          ? previous.copyWith(refreshing: true, clearFailure: true)
          : ManagerAttendanceState(query: requested),
    );
    try {
      final results = await Future.wait<AttendancePage>([
        _repository.listWorkspaceAttendance(
          scope.workspaceId,
          requested.copyWith(page: 1),
        ),
        _repository.listAttendanceRequests(scope.workspaceId),
      ]);
      if (!_current(scope, generation, requestId)) return;
      final records = results[0];
      final pending = results[1];
      if ([
        ...records.data,
        ...pending.data,
      ].any((item) => item.workspaceId != scope.workspaceId)) {
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
      if (!_current(scope, generation, requestId)) return;
      final failure = _failure(error, 'Unable to load attendance.');
      if (refresh &&
          (previous.records.isNotEmpty || previous.pending.isNotEmpty)) {
        emit(previous.copyWith(refreshing: false, failure: failure));
      } else {
        emit(
          ManagerAttendanceState(
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
      final page = await _repository.listWorkspaceAttendance(
        scope.workspaceId,
        previous.query.copyWith(page: previous.page + 1),
      );
      if (!_current(scope, generation, requestId)) return;
      if (page.data.any((item) => item.workspaceId != scope.workspaceId)) {
        throw const FormatException('Cross-workspace attendance response');
      }
      final ids = previous.records.map((item) => item.id).toSet();
      emit(
        previous.copyWith(
          records: [
            ...previous.records,
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
          failure: _failure(error, 'Unable to load more attendance.'),
        ),
      );
    }
  }

  Future<void> loadMorePending() async {
    final scope = _scope;
    final previous = state;
    if (scope == null ||
        previous.loadingMorePending ||
        !previous.hasMorePending) {
      return;
    }
    final generation = _generation;
    emit(previous.copyWith(loadingMorePending: true, clearFailure: true));
    try {
      final page = await _repository.listAttendanceRequests(
        scope.workspaceId,
        page: previous.pendingPage + 1,
      );
      if (!_scopeCurrent(scope, generation)) return;
      if (page.data.any((item) => item.workspaceId != scope.workspaceId)) {
        throw const FormatException('Cross-workspace attendance response');
      }
      final ids = previous.pending.map((item) => item.id).toSet();
      emit(
        previous.copyWith(
          pending: [
            ...previous.pending,
            ...page.data.where((item) => ids.add(item.id)),
          ],
          pendingPage: page.pagination.page,
          pendingTotalPages: page.pagination.totalPages,
          loadingMorePending: false,
        ),
      );
    } catch (error) {
      if (!_scopeCurrent(scope, generation)) return;
      emit(
        previous.copyWith(
          loadingMorePending: false,
          failure: _failure(error, 'Unable to load more requests.'),
        ),
      );
    }
  }

  Future<AttendanceRecordApi?> loadDetails(String attendanceId) async {
    final scope = _scope;
    if (scope == null || state.detailLoading) return null;
    final generation = _generation;
    emit(state.copyWith(detailLoading: true, clearFailure: true));
    try {
      final record = await _repository.getWorkspaceAttendance(
        scope.workspaceId,
        attendanceId,
      );
      if (!_scopeCurrent(scope, generation) ||
          record.workspaceId != scope.workspaceId) {
        return null;
      }
      emit(state.copyWith(selected: record, detailLoading: false));
      return record;
    } catch (error) {
      if (!_scopeCurrent(scope, generation)) return null;
      emit(
        state.copyWith(
          detailLoading: false,
          failure: _failure(error, 'Unable to load attendance details.'),
        ),
      );
      return null;
    }
  }

  Future<AttendanceMutationResult> review(
    String attendanceId,
    AttendanceReviewDecision decision, {
    String? rejectionReason,
  }) async {
    final scope = _scope;
    if (scope == null) return AttendanceMutationResult.failure;
    if (state.reviewingIds.contains(attendanceId)) {
      return AttendanceMutationResult.busy;
    }
    final normalizedReason = rejectionReason?.trim();
    if (decision == AttendanceReviewDecision.rejected &&
        (normalizedReason == null || normalizedReason.isEmpty)) {
      emit(
        state.copyWith(
          failure: const Failure(
            message: 'A rejection reason is required.',
            kind: FailureKind.validation,
          ),
        ),
      );
      return AttendanceMutationResult.failure;
    }
    if ((normalizedReason?.length ?? 0) > 1000) {
      emit(
        state.copyWith(
          failure: const Failure(
            message: 'Rejection reason is too long.',
            kind: FailureKind.validation,
          ),
        ),
      );
      return AttendanceMutationResult.failure;
    }
    final generation = _generation;
    emit(
      state.copyWith(
        reviewingIds: {...state.reviewingIds, attendanceId},
        clearFailure: true,
      ),
    );
    try {
      final record = await _repository.reviewAttendance(
        scope.workspaceId,
        attendanceId,
        decision,
        rejectionReason: normalizedReason,
      );
      if (!_scopeCurrent(scope, generation)) {
        return AttendanceMutationResult.stale;
      }
      if (record.workspaceId != scope.workspaceId ||
          record.id != attendanceId ||
          record.reviewStatus == AttendanceReviewStatus.pending ||
          record.reviewStatus == AttendanceReviewStatus.unknown) {
        _finishReview(
          attendanceId,
          failure: const Failure(
            message: 'The server returned an invalid review response.',
            kind: FailureKind.server,
          ),
        );
        return AttendanceMutationResult.failure;
      }
      _finishReview(attendanceId, record: record);
      onDashboardChanged?.call();
      return AttendanceMutationResult.success;
    } catch (error) {
      if (!_scopeCurrent(scope, generation)) {
        return AttendanceMutationResult.stale;
      }
      _finishReview(
        attendanceId,
        failure: _failure(error, 'Unable to review attendance.'),
      );
      return AttendanceMutationResult.failure;
    }
  }

  void _finishReview(
    String attendanceId, {
    AttendanceRecordApi? record,
    Failure? failure,
  }) {
    final reviewing = {...state.reviewingIds}..remove(attendanceId);
    emit(
      state.copyWith(
        reviewingIds: reviewing,
        records: record == null
            ? state.records
            : state.records
                  .map((item) => item.id == attendanceId ? record : item)
                  .toList(growable: false),
        pending: record == null
            ? state.pending
            : state.pending
                  .where((item) => item.id != attendanceId)
                  .toList(growable: false),
        selected: record ?? state.selected,
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
