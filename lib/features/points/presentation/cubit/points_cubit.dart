import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/points/data/points_models.dart';
import 'package:shiftly/features/points/data/points_repository.dart';
import 'package:shiftly/features/points/data/redemption_intent_storage.dart';
import 'package:shiftly/features/points/presentation/cubit/points_request_failure.dart';
import 'package:uuid/uuid.dart';

part 'points_state.dart';

class PointsCubit extends Cubit<PointsState> {
  PointsCubit(
    this._repository, {
    RedemptionIntentStorage? intentStorage,
    String Function()? uuidV4,
  }) : _intentStorage = intentStorage ?? MemoryRedemptionIntentStorage(),
      _uuidV4 = uuidV4 ?? const Uuid().v4,
      super(const PointsState());

  static const historyPageSize = 20;
  final PointsRepository _repository;
  final RedemptionIntentStorage _intentStorage;
  final String Function() _uuidV4;
  FeatureSessionScope? _scope;
  RedemptionIntent? _unresolvedIntent;
  Future<void>? _activeFullLoad;
  var _queuedFullLoad = false;
  var _generation = 0;
  var _walletRequestId = 0;
  var _calendarRequestId = 0;
  var _historyRequestId = 0;
  var _achievementRequestId = 0;

  void bindSession(FeatureSessionScope? scope) {
    final employee = scope?.isEmployee == true ? scope : null;
    if (_scope == employee) return;
    _scope = employee;
    _generation++;
    _walletRequestId++;
    _calendarRequestId++;
    _historyRequestId++;
    _achievementRequestId++;
    _activeFullLoad = null;
    _queuedFullLoad = false;
    _unresolvedIntent = null;
    emit(const PointsState());
    if (employee == null) return;
    final generation = _generation;
    unawaited(_restoreIntent(employee, generation));
    unawaited(load());
  }

  Future<void> _restoreIntent(FeatureSessionScope scope, int generation) async {
    final intent = await _intentStorage.read(scope);
    if (!_current(scope, generation) || intent == null) return;
    _unresolvedIntent = intent;
    emit(state.copyWith(
      hasUnresolvedRedemption: true,
      unresolvedRedPoints: intent.redPoints,
      canRetryRedemption: true,
    ));
  }

  Future<void> load({bool refresh = false}) async {
    final active = _activeFullLoad;
    if (active != null) {
      if (refresh) _queuedFullLoad = true;
      return active;
    }
    final operation = _performFullLoad(refresh: refresh);
    _activeFullLoad = operation;
    try {
      await operation;
    } finally {
      if (identical(_activeFullLoad, operation)) _activeFullLoad = null;
      if (_queuedFullLoad && _scope != null) {
        _queuedFullLoad = false;
        unawaited(load(refresh: true));
      }
    }
  }

  Future<void> _performFullLoad({required bool refresh}) async {
    final scope = _scope;
    if (scope == null) return;
    final generation = _generation;
    final localNow = WorkspaceTime.inWorkspace(DateTime.now(), scope.timezone);
    final month = state.visibleMonth ?? DateTime(localNow.year, localNow.month);
    final walletId = ++_walletRequestId;
    final calendarId = ++_calendarRequestId;
    final historyId = ++_historyRequestId;
    final achievementId = ++_achievementRequestId;
    emit(state.copyWith(
      visibleMonth: month,
      refreshing: refresh || state.wallet != null,
      loadingCalendar: true,
      loadingMoreHistory: false,
      clearFailure: true,
      clearPartialFailure: true,
      clearCalendarFailure: true,
      clearDomainCode: true,
    ));

    final results = await Future.wait<Object?>([
      _capture(() => _repository.loadWallet(scope.workspaceId)),
      _capture(() => _repository.loadCalendar(scope.workspaceId, month.year, month.month)),
      _capture(() => _repository.loadHistory(scope.workspaceId, page: 1, limit: historyPageSize)),
      _capture(() => _repository.loadAchievements(scope.workspaceId)),
    ]);
    if (!_current(scope, generation)) return;

    var next = state;
    final failures = <Failure>[];
    final wallet = results[0];
    if (walletId == _walletRequestId) {
      if (wallet is PointsWallet) next = next.copyWith(wallet: wallet);
      if (wallet is PointsRequestFailure) failures.add(wallet.failure);
    }
    final calendar = results[1];
    if (calendarId == _calendarRequestId && _sameMonth(next.visibleMonth, month)) {
      if (calendar is List<PerformanceDay>) {
        next = next.copyWith(calendar: calendar, calendarMonth: month, loadingCalendar: false, clearCalendarFailure: true);
      } else if (calendar is PointsRequestFailure) {
        failures.add(calendar.failure);
        next = next.copyWith(loadingCalendar: false, calendarFailure: calendar.failure);
      }
    }
    final history = results[2];
    if (historyId == _historyRequestId) {
      if (history is PointsHistoryPage) {
        next = next.copyWith(
          history: _deduplicate(history.data),
          historyPage: history.pagination.page,
          historyTotalPages: history.pagination.totalPages,
          loadingMoreHistory: false,
        );
      } else if (history is PointsRequestFailure) {
        failures.add(history.failure);
      }
    }
    final achievements = results[3];
    if (achievementId == _achievementRequestId) {
      if (achievements is List<Achievement>) next = next.copyWith(achievements: achievements);
      if (achievements is PointsRequestFailure) failures.add(achievements.failure);
    }
    final walletUnavailable = next.wallet == null;
    emit(next.copyWith(
      initialLoading: false,
      refreshing: false,
      failure: walletUnavailable ? failures.firstOrNull ?? const Failure(message: 'Unable to load your performance.') : null,
      partialFailure: !walletUnavailable && failures.isNotEmpty ? failures.first : null,
      clearFailure: !walletUnavailable,
      clearPartialFailure: !walletUnavailable && failures.isEmpty,
    ));
  }

  Future<void> changeMonth(DateTime month) async {
    final scope = _scope;
    if (scope == null) return;
    final normalized = DateTime(month.year, month.month);
    final generation = _generation;
    final requestId = ++_calendarRequestId;
    emit(state.copyWith(visibleMonth: normalized, loadingCalendar: true, clearCalendarFailure: true, clearPartialFailure: true));
    final result = await _capture(() => _repository.loadCalendar(scope.workspaceId, normalized.year, normalized.month));
    if (!_current(scope, generation) || requestId != _calendarRequestId || !_sameMonth(state.visibleMonth, normalized)) return;
    if (result is List<PerformanceDay>) {
      emit(state.copyWith(calendar: result, calendarMonth: normalized, loadingCalendar: false, clearCalendarFailure: true));
    } else if (result is PointsRequestFailure) {
      emit(state.copyWith(loadingCalendar: false, calendarFailure: result.failure, partialFailure: result.failure));
    }
  }

  Future<void> loadMoreHistory() async {
    final scope = _scope;
    if (scope == null || state.loadingMoreHistory || !state.hasMoreHistory) return;
    final generation = _generation;
    final requestId = _historyRequestId;
    final requestedPage = state.historyPage + 1;
    emit(state.copyWith(loadingMoreHistory: true, clearPartialFailure: true));
    final result = await _capture(() => _repository.loadHistory(scope.workspaceId, page: requestedPage, limit: historyPageSize));
    if (!_current(scope, generation) || requestId != _historyRequestId) return;
    if (result is PointsHistoryPage && result.pagination.page == requestedPage) {
      emit(state.copyWith(
        history: _deduplicate([...state.history, ...result.data]),
        historyPage: result.pagination.page,
        historyTotalPages: result.pagination.totalPages,
        loadingMoreHistory: false,
      ));
    } else {
      emit(state.copyWith(
        loadingMoreHistory: false,
        partialFailure: result is PointsRequestFailure ? result.failure : const Failure(message: 'Unable to load more history.'),
      ));
    }
  }

  Future<void> redeem(int redPoints, {bool retry = false}) async {
    final scope = _scope;
    if (scope == null || state.redeeming || redPoints < 1) return;
    final pending = _unresolvedIntent;
    if (pending != null && !retry) {
      emit(state.copyWith(
        canRetryRedemption: true,
        hasUnresolvedRedemption: true,
        unresolvedRedPoints: pending.redPoints,
        partialFailure: const Failure(message: 'An earlier redemption is unresolved. Retry that operation before starting another.'),
      ));
      return;
    }
    final request = pending ?? RedemptionIntent(workspaceId: scope.workspaceId, redPoints: redPoints, clientRedemptionId: _uuidV4());
    if (request.workspaceId != scope.workspaceId || request.redPoints != redPoints) return;
    final generation = _generation;
    if (pending == null) {
      try {
        await _intentStorage.write(scope, request);
      } catch (_) {
        if (_current(scope, generation)) {
          emit(state.copyWith(partialFailure: const Failure(message: 'The redemption could not be saved safely and was not submitted.')));
        }
        return;
      }
      if (!_current(scope, generation)) return;
      _unresolvedIntent = request;
    }
    emit(state.copyWith(
      redeeming: true,
      hasUnresolvedRedemption: true,
      unresolvedRedPoints: request.redPoints,
      clearFailure: true,
      clearPartialFailure: true,
      clearDomainCode: true,
      redemptionSucceeded: false,
      canRetryRedemption: false,
    ));
    try {
      await _repository.redeem(request);
      if (!_current(scope, generation)) return;
      await _intentStorage.clear(scope, request.clientRedemptionId);
      if (!_current(scope, generation)) return;
      _unresolvedIntent = null;
      emit(state.copyWith(
        redeeming: false,
        redemptionSucceeded: true,
        hasUnresolvedRedemption: false,
        unresolvedRedPoints: 0,
        canRetryRedemption: false,
      ));
      await load(refresh: true);
      if (_current(scope, generation)) emit(state.copyWith(redemptionSucceeded: true));
    } catch (error) {
      if (!_current(scope, generation)) return;
      final api = error is ApiException ? error : null;
      final terminal = _isConfirmedTerminal(api);
      if (terminal) {
        await _intentStorage.clear(scope, request.clientRedemptionId);
        if (!_current(scope, generation)) return;
        _unresolvedIntent = null;
      }
      emit(state.copyWith(
        redeeming: false,
        partialFailure: _failure(error),
        domainCode: api?.statusCode == 409 ? api?.code : null,
        hasUnresolvedRedemption: !terminal,
        unresolvedRedPoints: terminal ? 0 : request.redPoints,
        canRetryRedemption: !terminal,
      ));
    }
  }

  bool _isConfirmedTerminal(ApiException? error) => error != null && error.statusCode != null && error.statusCode! >= 400 && error.statusCode! < 500 && error.kind != FailureKind.cancelled && error.kind != FailureKind.timeout && error.kind != FailureKind.network;

  Future<Object?> _capture<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error) {
      return PointsRequestFailure(_failure(error));
    }
  }

  List<PointLedgerEntry> _deduplicate(List<PointLedgerEntry> entries) {
    final ids = <String>{};
    return entries.where((entry) => ids.add(entry.id)).toList(growable: false);
  }

  Failure _failure(Object error) => error is ApiException ? error.toFailure() : const Failure(message: 'Something went wrong. Please try again.');
  bool _current(FeatureSessionScope scope, int generation) => !isClosed && _scope == scope && _generation == generation;
  bool _sameMonth(DateTime? left, DateTime right) => left?.year == right.year && left?.month == right.month;
}
