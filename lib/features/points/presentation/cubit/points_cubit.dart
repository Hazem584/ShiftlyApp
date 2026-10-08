import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/points/data/points_models.dart';
import 'package:shiftly/features/points/data/points_repository.dart';
import 'package:uuid/uuid.dart';

part 'points_state.dart';

class PointsCubit extends Cubit<PointsState> {
  PointsCubit(this._repository, {String Function()? uuidV4})
    : _uuidV4 = uuidV4 ?? const Uuid().v4,
      super(const PointsState());

  static const historyPageSize = 20;
  final PointsRepository _repository;
  final String Function() _uuidV4;
  FeatureSessionScope? _scope;
  var _generation = 0;
  var _loadingHistory = false;
  RedemptionIntent? _retryableIntent;

  void bindSession(FeatureSessionScope? scope) {
    final employee = scope?.isEmployee == true ? scope : null;
    if (_scope == employee) return;
    _scope = employee;
    _generation++;
    _loadingHistory = false;
    _retryableIntent = null;
    emit(const PointsState());
    if (employee != null) unawaited(load());
  }

  Future<void> load({bool refresh = false}) async {
    final scope = _scope;
    if (scope == null) return;
    final generation = _generation;
    final previous = state;
    final localNow = WorkspaceTime.inWorkspace(DateTime.now(), scope.timezone);
    final month = refresh && previous.wallet != null
        ? previous.visibleMonth ?? DateTime(localNow.year, localNow.month)
        : DateTime(localNow.year, localNow.month);
    emit(
      previous.wallet == null
          ? PointsState(visibleMonth: month)
          : previous.copyWith(
              refreshing: refresh,
              clearFailure: true,
              clearPartialFailure: true,
              clearDomainCode: true,
            ),
    );

    PointsWallet? wallet;
    List<PerformanceDay>? calendar;
    PointsHistoryPage? history;
    List<Achievement>? achievements;
    final failures = <Failure>[];
    Future<void> loadWallet() async {
      try {
        wallet = await _repository.loadWallet(scope.workspaceId);
      } catch (error) {
        failures.add(_failure(error));
      }
    }

    Future<void> loadCalendar() async {
      try {
        calendar = await _repository.loadCalendar(
          scope.workspaceId,
          month.year,
          month.month,
        );
      } catch (error) {
        failures.add(_failure(error));
      }
    }

    Future<void> loadHistory() async {
      try {
        history = await _repository.loadHistory(
          scope.workspaceId,
          page: 1,
          limit: historyPageSize,
        );
      } catch (error) {
        failures.add(_failure(error));
      }
    }

    Future<void> loadAchievements() async {
      try {
        achievements = await _repository.loadAchievements(scope.workspaceId);
      } catch (error) {
        failures.add(_failure(error));
      }
    }

    await Future.wait([
      loadWallet(),
      loadCalendar(),
      loadHistory(),
      loadAchievements(),
    ]);
    if (!_current(scope, generation)) return;
    if (wallet == null && previous.wallet == null) {
      emit(
        PointsState(
          initialLoading: false,
          visibleMonth: month,
          failure:
              failures.firstOrNull ??
              const Failure(message: 'Unable to load your performance.'),
        ),
      );
      return;
    }
    emit(
      PointsState(
        initialLoading: false,
        wallet: wallet ?? previous.wallet,
        calendar: calendar ?? previous.calendar,
        history: history?.data ?? previous.history,
        achievements: achievements ?? previous.achievements,
        visibleMonth: month,
        historyPage: history?.pagination.page ?? previous.historyPage,
        historyTotalPages:
            history?.pagination.totalPages ?? previous.historyTotalPages,
        partialFailure: failures.isEmpty ? null : failures.first,
      ),
    );
  }

  Future<void> changeMonth(DateTime month) async {
    final scope = _scope;
    if (scope == null || state.loadingCalendar) return;
    final normalized = DateTime(month.year, month.month);
    final generation = _generation;
    emit(
      state.copyWith(
        visibleMonth: normalized,
        loadingCalendar: true,
        clearPartialFailure: true,
      ),
    );
    try {
      final days = await _repository.loadCalendar(
        scope.workspaceId,
        normalized.year,
        normalized.month,
      );
      if (!_current(scope, generation)) return;
      emit(state.copyWith(calendar: days, loadingCalendar: false));
    } catch (error) {
      if (!_current(scope, generation)) return;
      emit(
        state.copyWith(loadingCalendar: false, partialFailure: _failure(error)),
      );
    }
  }

  Future<void> loadMoreHistory() async {
    final scope = _scope;
    if (scope == null || _loadingHistory || !state.hasMoreHistory) return;
    _loadingHistory = true;
    final generation = _generation;
    emit(state.copyWith(loadingMoreHistory: true, clearPartialFailure: true));
    try {
      final page = await _repository.loadHistory(
        scope.workspaceId,
        page: state.historyPage + 1,
        limit: historyPageSize,
      );
      if (!_current(scope, generation)) return;
      final ids = state.history.map((item) => item.id).toSet();
      emit(
        state.copyWith(
          history: [
            ...state.history,
            ...page.data.where((item) => ids.add(item.id)),
          ],
          historyPage: page.pagination.page,
          historyTotalPages: page.pagination.totalPages,
          loadingMoreHistory: false,
        ),
      );
    } catch (error) {
      if (_current(scope, generation)) {
        emit(
          state.copyWith(
            loadingMoreHistory: false,
            partialFailure: _failure(error),
          ),
        );
      }
    } finally {
      _loadingHistory = false;
    }
  }

  Future<void> redeem(int redPoints, {bool retry = false}) async {
    final scope = _scope;
    if (scope == null || state.redeeming || redPoints < 1) return;
    final intent = retry ? _retryableIntent : null;
    final request =
        intent ??
        RedemptionIntent(
          workspaceId: scope.workspaceId,
          redPoints: redPoints,
          clientRedemptionId: _uuidV4(),
        );
    if (request.workspaceId != scope.workspaceId ||
        request.redPoints != redPoints) {
      return;
    }
    _retryableIntent = request;
    final generation = _generation;
    emit(
      state.copyWith(
        redeeming: true,
        clearFailure: true,
        clearPartialFailure: true,
        clearDomainCode: true,
        redemptionSucceeded: false,
      ),
    );
    try {
      await _repository.redeem(request);
      if (!_current(scope, generation)) return;
      _retryableIntent = null;
      emit(state.copyWith(redeeming: false, redemptionSucceeded: true));
      await load(refresh: true);
      if (_current(scope, generation)) {
        emit(state.copyWith(redemptionSucceeded: true));
      }
    } catch (error) {
      if (!_current(scope, generation)) return;
      final api = error is ApiException ? error : null;
      final domain = api?.statusCode == 409 ? api?.code : null;
      final uncertain =
          api == null ||
          api.kind == FailureKind.network ||
          api.kind == FailureKind.timeout ||
          api.kind == FailureKind.server ||
          (api.statusCode == null && api.kind == FailureKind.unknown);
      if (!uncertain) _retryableIntent = null;
      emit(
        state.copyWith(
          redeeming: false,
          partialFailure: _failure(error),
          domainCode: domain,
          canRetryRedemption: uncertain,
        ),
      );
    }
  }

  Failure _failure(Object error) => error is ApiException
      ? error.toFailure()
      : const Failure(message: 'Something went wrong. Please try again.');
  bool _current(FeatureSessionScope scope, int generation) =>
      !isClosed && _scope == scope && _generation == generation;
}
