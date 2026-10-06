part of '../../employee_shifts_cubit.dart';

class EmployeeShiftsCubit extends Cubit<EmployeeShiftsState> {
  EmployeeShiftsCubit(
    this._shifts,
    this._attendance, {
    this.onAttendanceChanged,
    this.onDashboardChanged,
  }) : super(const EmployeeShiftsState());

  final ShiftRepository _shifts;
  final AttendanceRepository _attendance;
  final Future<void> Function()? onAttendanceChanged;
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
    emit(const EmployeeShiftsState());
    if (authorized != null) unawaited(load());
  }

  Future<void> load({ShiftQuery? query, bool refresh = false}) async {
    final scope = _scope;
    if (scope == null) return;
    final generation = _generation;
    final requestId = ++_requestId;
    final requested = query ?? state.query;
    final previous = state;
    emit(
      refresh && previous.records.isNotEmpty
          ? previous.copyWith(refreshing: true, clearFailure: true)
          : EmployeeShiftsState(query: requested),
    );
    try {
      final page = await _shifts.listMyShifts(
        scope.workspaceId,
        requested.copyWith(page: 1),
      );
      if (!_current(scope, generation, requestId)) return;
      final records = page.data
          .where((item) => item.workspaceId == scope.workspaceId)
          .toList(growable: false);
      emit(
        EmployeeShiftsState(
          initialLoading: false,
          records: records,
          query: requested.copyWith(page: 1),
          page: page.pagination.page,
          totalPages: page.pagination.totalPages,
        ),
      );
    } catch (error) {
      if (!_current(scope, generation, requestId)) return;
      final failure = _failure(error, 'Unable to load your shifts.');
      if (refresh && previous.records.isNotEmpty) {
        emit(previous.copyWith(refreshing: false, failure: failure));
      } else {
        emit(
          EmployeeShiftsState(
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
      final page = await _shifts.listMyShifts(
        scope.workspaceId,
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
          failure: _failure(error, 'Unable to load more shifts.'),
        ),
      );
    }
  }

  Future<ShiftRecord?> loadDetails(String shiftId) async {
    final scope = _scope;
    if (scope == null || state.detailLoading) return null;
    final generation = _generation;
    emit(state.copyWith(detailLoading: true, clearFailure: true));
    try {
      final record = await _shifts.getMyShift(shiftId);
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
          failure: _failure(error, 'Unable to load shift details.'),
        ),
      );
      return null;
    }
  }

  Future<ClockMutationResult> clockIn(String shiftId) =>
      _clock(shiftId, clockIn: true);

  Future<ClockMutationResult> clockOut(String shiftId) =>
      _clock(shiftId, clockIn: false);

  Future<ClockMutationResult> _clock(
    String shiftId, {
    required bool clockIn,
  }) async {
    final scope = _scope;
    if (scope == null) return ClockMutationResult.failure;
    final active = clockIn ? state.clockingInIds : state.clockingOutIds;
    if (active.contains(shiftId)) return ClockMutationResult.busy;
    final generation = _generation;
    final next = {...active, shiftId};
    emit(
      clockIn
          ? state.copyWith(clockingInIds: next, clearFailure: true)
          : state.copyWith(clockingOutIds: next, clearFailure: true),
    );
    try {
      final attendance = clockIn
          ? await _attendance.clockIn(shiftId)
          : await _attendance.clockOut(shiftId);
      if (!_scopeCurrent(scope, generation)) return ClockMutationResult.stale;
      if (attendance.workspaceId != scope.workspaceId ||
          attendance.shiftId != shiftId ||
          attendance.source != AttendanceSource.legacyShift ||
          attendance.shift == null) {
        _finishClock(
          shiftId,
          clockIn: clockIn,
          failure: const Failure(
            message: 'The server returned an invalid attendance response.',
            kind: FailureKind.server,
          ),
        );
        return ClockMutationResult.failure;
      }
      final summary = ShiftAttendanceSummary(
        id: attendance.id,
        clockInAt: attendance.clockInAt,
        clockOutAt: attendance.clockOutAt,
        reviewStatus: attendance.reviewStatus,
        minutesLate: attendance.minutesLate,
        workedMinutes: attendance.workedMinutes,
      );
      final updated = state.records
          .map(
            (item) => item.id == shiftId
                ? item.copyWith(
                    status: attendance.shift!.status,
                    attendance: summary,
                  )
                : item,
          )
          .toList(growable: false);
      final selected = state.selected?.id == shiftId
          ? state.selected!.copyWith(
              status: attendance.shift!.status,
              attendance: summary,
            )
          : state.selected;
      _finishClock(
        shiftId,
        clockIn: clockIn,
        records: updated,
        selected: selected,
      );
      await onAttendanceChanged?.call();
      onDashboardChanged?.call();
      return ClockMutationResult.success;
    } catch (error) {
      if (!_scopeCurrent(scope, generation)) return ClockMutationResult.stale;
      _finishClock(
        shiftId,
        clockIn: clockIn,
        failure: _failure(
          error,
          clockIn ? 'Unable to clock in.' : 'Unable to clock out.',
        ),
      );
      return ClockMutationResult.failure;
    }
  }

  void _finishClock(
    String shiftId, {
    required bool clockIn,
    List<ShiftRecord>? records,
    ShiftRecord? selected,
    Failure? failure,
  }) {
    final values = {...(clockIn ? state.clockingInIds : state.clockingOutIds)}
      ..remove(shiftId);
    emit(
      state.copyWith(
        records: records,
        selected: selected,
        clockingInIds: clockIn ? values : state.clockingInIds,
        clockingOutIds: clockIn ? state.clockingOutIds : values,
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
