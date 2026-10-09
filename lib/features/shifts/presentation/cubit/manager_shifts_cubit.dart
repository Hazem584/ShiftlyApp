import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

enum ShiftMutationResult { success, failure, busy, stale }

class ManagerShiftsState extends Equatable {
  const ManagerShiftsState({
    this.initialLoading = true,
    this.records = const [],
    this.query = const ShiftQuery(),
    this.page = 1,
    this.total = 0,
    this.totalPages = 0,
    this.refreshing = false,
    this.loadingMore = false,
    this.creating = false,
    this.updatingId,
    this.cancellingId,
    this.selected,
    this.detailLoading = false,
    this.failure,
  });

  final bool initialLoading;
  final List<ShiftRecord> records;
  final ShiftQuery query;
  final int page;
  final int total;
  final int totalPages;
  final bool refreshing;
  final bool loadingMore;
  final bool creating;
  final String? updatingId;
  final String? cancellingId;
  final ShiftRecord? selected;
  final bool detailLoading;
  final Failure? failure;

  bool get hasMore => page < totalPages;

  ManagerShiftsState copyWith({
    bool? initialLoading,
    List<ShiftRecord>? records,
    ShiftQuery? query,
    int? page,
    int? total,
    int? totalPages,
    bool? refreshing,
    bool? loadingMore,
    bool? creating,
    String? updatingId,
    bool clearUpdating = false,
    String? cancellingId,
    bool clearCancelling = false,
    ShiftRecord? selected,
    bool clearSelected = false,
    bool? detailLoading,
    Failure? failure,
    bool clearFailure = false,
  }) => ManagerShiftsState(
    initialLoading: initialLoading ?? this.initialLoading,
    records: records ?? this.records,
    query: query ?? this.query,
    page: page ?? this.page,
    total: total ?? this.total,
    totalPages: totalPages ?? this.totalPages,
    refreshing: refreshing ?? this.refreshing,
    loadingMore: loadingMore ?? this.loadingMore,
    creating: creating ?? this.creating,
    updatingId: clearUpdating ? null : updatingId ?? this.updatingId,
    cancellingId: clearCancelling ? null : cancellingId ?? this.cancellingId,
    selected: clearSelected ? null : selected ?? this.selected,
    detailLoading: detailLoading ?? this.detailLoading,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [
    initialLoading,
    records,
    query,
    page,
    total,
    totalPages,
    refreshing,
    loadingMore,
    creating,
    updatingId,
    cancellingId,
    selected,
    detailLoading,
    failure,
  ];
}

class ManagerShiftsCubit extends Cubit<ManagerShiftsState> {
  ManagerShiftsCubit(this._repository, {this.onDashboardChanged})
    : super(const ManagerShiftsState());

  final ShiftRepository _repository;
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
    emit(const ManagerShiftsState());
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
          : ManagerShiftsState(query: requested),
    );
    try {
      final page = await _repository.listWorkspaceShifts(
        scope.workspaceId,
        requested.copyWith(page: 1),
      );
      if (!_current(scope, generation, requestId)) return;
      if (page.data.any((item) => item.workspaceId != scope.workspaceId)) {
        throw const FormatException('Cross-workspace shift response');
      }
      emit(
        ManagerShiftsState(
          initialLoading: false,
          records: page.data,
          query: requested.copyWith(page: 1),
          page: page.pagination.page,
          total: page.pagination.total,
          totalPages: page.pagination.totalPages,
        ),
      );
    } catch (error) {
      if (!_current(scope, generation, requestId)) return;
      final failure = _failure(error, 'Unable to load shifts.');
      if (refresh && previous.records.isNotEmpty) {
        emit(previous.copyWith(refreshing: false, failure: failure));
      } else {
        emit(
          ManagerShiftsState(
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
      final page = await _repository.listWorkspaceShifts(
        scope.workspaceId,
        previous.query.copyWith(page: previous.page + 1),
      );
      if (!_current(scope, generation, requestId)) return;
      if (page.data.any((item) => item.workspaceId != scope.workspaceId)) {
        throw const FormatException('Cross-workspace shift response');
      }
      final ids = previous.records.map((item) => item.id).toSet();
      emit(
        previous.copyWith(
          records: [
            ...previous.records,
            ...page.data.where((item) => ids.add(item.id)),
          ],
          page: page.pagination.page,
          total: page.pagination.total,
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
      final record = await _repository.getWorkspaceShift(
        scope.workspaceId,
        shiftId,
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
          failure: _failure(error, 'Unable to load shift details.'),
        ),
      );
      return null;
    }
  }

  Future<ShiftMutationResult> create(CreateShiftInput input) async {
    final scope = _scope;
    if (scope == null) return ShiftMutationResult.failure;
    if (state.creating) return ShiftMutationResult.busy;
    final validation = validateShift(
      startsAt: input.startsAt,
      endsAt: input.endsAt,
      breakMinutes: input.breakMinutes,
      graceMinutes: input.graceMinutes,
    );
    if (validation != null) {
      emit(state.copyWith(failure: validation));
      return ShiftMutationResult.failure;
    }
    final generation = _generation;
    emit(state.copyWith(creating: true, clearFailure: true));
    try {
      final record = await _repository.createShift(scope.workspaceId, input);
      if (!_scopeCurrent(scope, generation)) return ShiftMutationResult.stale;
      if (record.workspaceId != scope.workspaceId) {
        emit(state.copyWith(creating: false, failure: _invalidResponse()));
        return ShiftMutationResult.failure;
      }
      emit(
        state.copyWith(
          records: _upsert(state.records, record),
          total: state.records.any((item) => item.id == record.id)
              ? state.total
              : state.total + 1,
          creating: false,
        ),
      );
      onDashboardChanged?.call();
      return ShiftMutationResult.success;
    } catch (error) {
      if (!_scopeCurrent(scope, generation)) return ShiftMutationResult.stale;
      emit(
        state.copyWith(
          creating: false,
          failure: _failure(error, 'Unable to create the shift.'),
        ),
      );
      return ShiftMutationResult.failure;
    }
  }

  Future<ShiftMutationResult> update(
    String shiftId,
    UpdateShiftInput input,
  ) async {
    final scope = _scope;
    if (scope == null) return ShiftMutationResult.failure;
    if (state.updatingId == shiftId) return ShiftMutationResult.busy;
    final current = state.records
        .where((item) => item.id == shiftId)
        .firstOrNull;
    final startsAt = input.startsAt ?? current?.startsAt;
    final endsAt = input.endsAt ?? current?.endsAt;
    final breakMinutes = input.breakMinutes ?? current?.breakMinutes;
    final graceMinutes = input.graceMinutes ?? current?.graceMinutes;
    if (startsAt == null ||
        endsAt == null ||
        breakMinutes == null ||
        graceMinutes == null) {
      return ShiftMutationResult.failure;
    }
    final validation = validateShift(
      startsAt: startsAt,
      endsAt: endsAt,
      breakMinutes: breakMinutes,
      graceMinutes: graceMinutes,
    );
    if (validation != null) {
      emit(state.copyWith(failure: validation));
      return ShiftMutationResult.failure;
    }
    final generation = _generation;
    emit(state.copyWith(updatingId: shiftId, clearFailure: true));
    try {
      final record = await _repository.updateShift(
        scope.workspaceId,
        shiftId,
        input,
      );
      if (!_scopeCurrent(scope, generation)) return ShiftMutationResult.stale;
      if (record.workspaceId != scope.workspaceId) {
        emit(state.copyWith(clearUpdating: true, failure: _invalidResponse()));
        return ShiftMutationResult.failure;
      }
      emit(
        state.copyWith(
          records: _upsert(state.records, record),
          selected: state.selected?.id == record.id ? record : state.selected,
          clearUpdating: true,
        ),
      );
      onDashboardChanged?.call();
      return ShiftMutationResult.success;
    } catch (error) {
      if (!_scopeCurrent(scope, generation)) return ShiftMutationResult.stale;
      emit(
        state.copyWith(
          clearUpdating: true,
          failure: _failure(error, 'Unable to update the shift.'),
        ),
      );
      return ShiftMutationResult.failure;
    }
  }

  Future<ShiftMutationResult> cancel(String shiftId) async {
    final scope = _scope;
    if (scope == null) return ShiftMutationResult.failure;
    if (state.cancellingId == shiftId) return ShiftMutationResult.busy;
    final generation = _generation;
    emit(state.copyWith(cancellingId: shiftId, clearFailure: true));
    try {
      final record = await _repository.cancelShift(scope.workspaceId, shiftId);
      if (!_scopeCurrent(scope, generation)) return ShiftMutationResult.stale;
      if (record.workspaceId != scope.workspaceId ||
          record.status != ShiftStatus.cancelled) {
        emit(
          state.copyWith(clearCancelling: true, failure: _invalidResponse()),
        );
        return ShiftMutationResult.failure;
      }
      emit(
        state.copyWith(
          records: _upsert(state.records, record),
          selected: state.selected?.id == record.id ? record : state.selected,
          clearCancelling: true,
        ),
      );
      onDashboardChanged?.call();
      return ShiftMutationResult.success;
    } catch (error) {
      if (!_scopeCurrent(scope, generation)) return ShiftMutationResult.stale;
      emit(
        state.copyWith(
          clearCancelling: true,
          failure: _failure(error, 'Unable to cancel the shift.'),
        ),
      );
      return ShiftMutationResult.failure;
    }
  }

  static Failure? validateShift({
    required DateTime startsAt,
    required DateTime endsAt,
    required int breakMinutes,
    required int graceMinutes,
  }) {
    if (!endsAt.isAfter(startsAt)) {
      return const Failure(
        message: 'Shift end must be after its start.',
        kind: FailureKind.validation,
      );
    }
    final duration = endsAt.difference(startsAt).inMinutes;
    if (duration > 1440) {
      return const Failure(
        message: 'Shift duration cannot exceed 24 hours.',
        kind: FailureKind.validation,
      );
    }
    if (breakMinutes < 0 || breakMinutes > 1440 || breakMinutes >= duration) {
      return const Failure(
        message: 'Break must be shorter than the shift.',
        kind: FailureKind.validation,
      );
    }
    if (graceMinutes < 0 || graceMinutes > 1440) {
      return const Failure(
        message: 'Grace minutes must be between 0 and 1440.',
        kind: FailureKind.validation,
      );
    }
    return null;
  }

  List<ShiftRecord> _upsert(List<ShiftRecord> records, ShiftRecord record) {
    final values = [record, ...records.where((item) => item.id != record.id)];
    values.sort((a, b) => b.startsAt.compareTo(a.startsAt));
    return values;
  }

  Failure _failure(Object error, String fallback) =>
      error is ApiException ? error.toFailure() : Failure(message: fallback);
  Failure _invalidResponse() => const Failure(
    message: 'The server returned an invalid shift response.',
    kind: FailureKind.server,
  );
  bool _current(FeatureSessionScope scope, int generation, int requestId) =>
      _scopeCurrent(scope, generation) && _requestId == requestId;
  bool _scopeCurrent(FeatureSessionScope scope, int generation) =>
      !isClosed && _scope == scope && _generation == generation;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
