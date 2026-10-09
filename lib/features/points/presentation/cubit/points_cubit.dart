import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/points/application/storage/memory_redemption_intent_storage.dart';
import 'package:shiftly/features/points/domain/entities/points_models.dart';
import 'package:shiftly/features/points/domain/repositories/points_repository.dart';
import 'package:shiftly/features/points/domain/repositories/redemption_intent_storage.dart';
import 'package:shiftly/features/points/presentation/cubit/points_request_failure.dart';
import 'package:uuid/uuid.dart';

class PointsState extends Equatable {
  const PointsState({
    this.initialLoading = true,
    this.refreshing = false,
    this.loadingCalendar = false,
    this.loadingMoreHistory = false,
    this.redeeming = false,
    this.redemptionSucceeded = false,
    this.canRetryRedemption = false,
    this.hasUnresolvedRedemption = false,
    this.unresolvedRedPoints = 0,
    this.wallet,
    this.calendar = const [],
    this.calendarMonth,
    this.history = const [],
    this.achievements = const [],
    this.visibleMonth,
    this.historyPage = 1,
    this.historyTotalPages = 0,
    this.failure,
    this.partialFailure,
    this.calendarFailure,
    this.domainCode,
  });

  final bool initialLoading;
  final bool refreshing;
  final bool loadingCalendar;
  final bool loadingMoreHistory;
  final bool redeeming;
  final bool redemptionSucceeded;
  final bool canRetryRedemption;
  final bool hasUnresolvedRedemption;
  final int unresolvedRedPoints;
  final PointsWallet? wallet;
  final List<PerformanceDay> calendar;
  final DateTime? calendarMonth;
  final List<PointLedgerEntry> history;
  final List<Achievement> achievements;
  final DateTime? visibleMonth;
  final int historyPage;
  final int historyTotalPages;
  final Failure? failure;
  final Failure? partialFailure;
  final Failure? calendarFailure;
  final String? domainCode;

  bool get hasMoreHistory => historyPage < historyTotalPages;
  bool get calendarMatchesVisibleMonth =>
      calendarMonth != null &&
      visibleMonth != null &&
      calendarMonth!.year == visibleMonth!.year &&
      calendarMonth!.month == visibleMonth!.month;
  List<PerformanceDay> get visibleCalendar =>
      calendarMatchesVisibleMonth ? calendar : const [];

  PointsState copyWith({
    bool? initialLoading,
    bool? refreshing,
    bool? loadingCalendar,
    bool? loadingMoreHistory,
    bool? redeeming,
    bool? redemptionSucceeded,
    bool? canRetryRedemption,
    bool? hasUnresolvedRedemption,
    int? unresolvedRedPoints,
    PointsWallet? wallet,
    List<PerformanceDay>? calendar,
    DateTime? calendarMonth,
    List<PointLedgerEntry>? history,
    List<Achievement>? achievements,
    DateTime? visibleMonth,
    int? historyPage,
    int? historyTotalPages,
    Failure? failure,
    Failure? partialFailure,
    Failure? calendarFailure,
    String? domainCode,
    bool clearFailure = false,
    bool clearPartialFailure = false,
    bool clearCalendarFailure = false,
    bool clearDomainCode = false,
  }) => PointsState(
    initialLoading: initialLoading ?? this.initialLoading,
    refreshing: refreshing ?? this.refreshing,
    loadingCalendar: loadingCalendar ?? this.loadingCalendar,
    loadingMoreHistory: loadingMoreHistory ?? this.loadingMoreHistory,
    redeeming: redeeming ?? this.redeeming,
    redemptionSucceeded: redemptionSucceeded ?? this.redemptionSucceeded,
    canRetryRedemption: canRetryRedemption ?? this.canRetryRedemption,
    hasUnresolvedRedemption:
        hasUnresolvedRedemption ?? this.hasUnresolvedRedemption,
    unresolvedRedPoints: unresolvedRedPoints ?? this.unresolvedRedPoints,
    wallet: wallet ?? this.wallet,
    calendar: calendar ?? this.calendar,
    calendarMonth: calendarMonth ?? this.calendarMonth,
    history: history ?? this.history,
    achievements: achievements ?? this.achievements,
    visibleMonth: visibleMonth ?? this.visibleMonth,
    historyPage: historyPage ?? this.historyPage,
    historyTotalPages: historyTotalPages ?? this.historyTotalPages,
    failure: clearFailure ? null : failure ?? this.failure,
    partialFailure: clearPartialFailure
        ? null
        : partialFailure ?? this.partialFailure,
    calendarFailure: clearCalendarFailure
        ? null
        : calendarFailure ?? this.calendarFailure,
    domainCode: clearDomainCode ? null : domainCode ?? this.domainCode,
  );

  @override
  List<Object?> get props => [
    initialLoading,
    refreshing,
    loadingCalendar,
    loadingMoreHistory,
    redeeming,
    redemptionSucceeded,
    canRetryRedemption,
    hasUnresolvedRedemption,
    unresolvedRedPoints,
    wallet,
    calendar,
    calendarMonth,
    history,
    achievements,
    visibleMonth,
    historyPage,
    historyTotalPages,
    failure,
    partialFailure,
    calendarFailure,
    domainCode,
  ];
}

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
  Object? _redemptionClaim;
  bool _intentReady = false;
  final Map<String, Future<void>> _scopeOperations = {};
  String _intentScopeKey(FeatureSessionScope scope) =>
      '${scope.userId}:${scope.workspaceId}:${scope.membershipId}';
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
    _redemptionClaim = null;
    _intentReady = false;
    emit(const PointsState());
    if (employee == null) return;
    final generation = _generation;
    unawaited(_restoreIntent(employee, generation));
    unawaited(load());
  }

  Future<void> _restoreIntent(FeatureSessionScope scope, int generation) async {
    final claim = Object();
    _redemptionClaim = claim;
    emit(state.copyWith(redeeming: true));
    try {
      // A scope may be rebound while its previous storage write is in flight.
      await _scopeOperations[_intentScopeKey(scope)];
      final intent = await _intentStorage.read(scope);
      if (!_current(scope, generation)) return;
      _unresolvedIntent = intent;
      _intentReady = true;
      if (intent != null) {
        emit(
          state.copyWith(
            hasUnresolvedRedemption: true,
            unresolvedRedPoints: intent.redPoints,
            canRetryRedemption: true,
          ),
        );
      }
    } catch (_) {
      if (_current(scope, generation)) {
        emit(
          state.copyWith(
            partialFailure: const Failure(
              message: 'Saved redemption could not be checked. Try again before starting a new operation.',
            ),
          ),
        );
      }
    } finally {
      if (identical(_redemptionClaim, claim)) {
        _redemptionClaim = null;
        if (_current(scope, generation)) emit(state.copyWith(redeeming: false));
      }
    }
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
    emit(
      state.copyWith(
        visibleMonth: month,
        refreshing: refresh || state.wallet != null,
        loadingCalendar: true,
        loadingMoreHistory: false,
        clearFailure: true,
        clearPartialFailure: true,
        clearCalendarFailure: true,
        clearDomainCode: true,
      ),
    );

    final results = await Future.wait<Object?>([
      _capture(() => _repository.loadWallet(scope.workspaceId)),
      _capture(
        () => _repository.loadCalendar(
          scope.workspaceId,
          month.year,
          month.month,
        ),
      ),
      _capture(
        () => _repository.loadHistory(
          scope.workspaceId,
          page: 1,
          limit: historyPageSize,
        ),
      ),
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
    if (calendarId == _calendarRequestId &&
        _sameMonth(next.visibleMonth, month)) {
      if (calendar is List<PerformanceDay>) {
        next = next.copyWith(
          calendar: calendar,
          calendarMonth: month,
          loadingCalendar: false,
          clearCalendarFailure: true,
        );
      } else if (calendar is PointsRequestFailure) {
        failures.add(calendar.failure);
        next = next.copyWith(
          loadingCalendar: false,
          calendarFailure: calendar.failure,
        );
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
      if (achievements is List<Achievement>) {
        next = next.copyWith(achievements: achievements);
      }
      if (achievements is PointsRequestFailure) {
        failures.add(achievements.failure);
      }
    }
    final walletUnavailable = next.wallet == null;
    emit(
      next.copyWith(
        initialLoading: false,
        refreshing: false,
        failure: walletUnavailable
            ? failures.firstOrNull ??
                  const Failure(message: 'Unable to load your performance.')
            : null,
        partialFailure: !walletUnavailable && failures.isNotEmpty
            ? failures.first
            : null,
        clearFailure: !walletUnavailable,
        clearPartialFailure: !walletUnavailable && failures.isEmpty,
      ),
    );
  }

  Future<void> changeMonth(DateTime month) async {
    final scope = _scope;
    if (scope == null) return;
    final normalized = DateTime(month.year, month.month);
    final generation = _generation;
    final requestId = ++_calendarRequestId;
    emit(
      state.copyWith(
        visibleMonth: normalized,
        loadingCalendar: true,
        clearCalendarFailure: true,
        clearPartialFailure: true,
      ),
    );
    final result = await _capture(
      () => _repository.loadCalendar(
        scope.workspaceId,
        normalized.year,
        normalized.month,
      ),
    );
    if (!_current(scope, generation) ||
        requestId != _calendarRequestId ||
        !_sameMonth(state.visibleMonth, normalized)) {
      return;
    }
    if (result is List<PerformanceDay>) {
      emit(
        state.copyWith(
          calendar: result,
          calendarMonth: normalized,
          loadingCalendar: false,
          clearCalendarFailure: true,
        ),
      );
    } else if (result is PointsRequestFailure) {
      emit(
        state.copyWith(
          loadingCalendar: false,
          calendarFailure: result.failure,
          partialFailure: result.failure,
        ),
      );
    }
  }

  Future<void> loadMoreHistory() async {
    final scope = _scope;
    if (scope == null || state.loadingMoreHistory || !state.hasMoreHistory) {
      return;
    }
    final generation = _generation;
    final requestId = _historyRequestId;
    final requestedPage = state.historyPage + 1;
    emit(state.copyWith(loadingMoreHistory: true, clearPartialFailure: true));
    final result = await _capture(
      () => _repository.loadHistory(
        scope.workspaceId,
        page: requestedPage,
        limit: historyPageSize,
      ),
    );
    if (!_current(scope, generation) || requestId != _historyRequestId) return;
    if (result is PointsHistoryPage &&
        result.pagination.page == requestedPage) {
      emit(
        state.copyWith(
          history: _deduplicate([...state.history, ...result.data]),
          historyPage: result.pagination.page,
          historyTotalPages: result.pagination.totalPages,
          loadingMoreHistory: false,
        ),
      );
    } else {
      emit(
        state.copyWith(
          loadingMoreHistory: false,
          partialFailure: result is PointsRequestFailure
              ? result.failure
              : const Failure(message: 'Unable to load more history.'),
        ),
      );
    }
  }

  Future<void> redeem(int redPoints, {bool retry = false}) async {
    final scope = _scope;
    if (scope == null || _redemptionClaim != null || redPoints < 1) return;
    final generation = _generation;
    if (!_intentReady) {
      await _restoreIntent(scope, generation);
      return;
    }
    final pending = _unresolvedIntent;
    if (pending != null && !retry) {
      emit(
        state.copyWith(
          canRetryRedemption: true,
          hasUnresolvedRedemption: true,
          unresolvedRedPoints: pending.redPoints,
          partialFailure: const Failure(
            message: 'An earlier redemption is unresolved. Retry that operation before starting another.',
          ),
        ),
      );
      return;
    }
    // Claim synchronously, before generating an identity or awaiting storage.
    final claim = Object();
    _redemptionClaim = claim;
    final completion = Completer<void>();
    final scopeKey = _intentScopeKey(scope);
    _scopeOperations[scopeKey] = completion.future;
    try {
      final request =
          pending ??
          RedemptionIntent(
            workspaceId: scope.workspaceId,
            redPoints: redPoints,
            clientRedemptionId: _uuidV4(),
          );
      if (request.workspaceId != scope.workspaceId ||
          request.redPoints != redPoints) {
        return;
      }
      emit(
        state.copyWith(
          redeeming: true,
          clearPartialFailure: true,
          clearDomainCode: true,
          redemptionSucceeded: false,
          canRetryRedemption: false,
        ),
      );
      if (pending == null) {
        try {
          await _intentStorage.write(scope, request);
        } catch (_) {
          // A storage implementation may throw after persisting. Re-read before
          // allowing another UUID; if the read fails, keep fresh actions blocked.
          RedemptionIntent? saved;
          var checked = false;
          try {
            saved = await _intentStorage.read(scope);
            checked = true;
          } catch (_) {}
          if (_current(scope, generation)) {
            _unresolvedIntent = saved;
            _intentReady = checked;
            emit(
              state.copyWith(
                redeeming: false,
                hasUnresolvedRedemption: saved != null,
                unresolvedRedPoints: saved?.redPoints ?? 0,
                canRetryRedemption: saved != null,
                partialFailure: const Failure(
                  message: 'The redemption could not be saved safely and was not submitted.',
                ),
              ),
            );
          }
          return;
        }
        if (!_current(scope, generation)) return;
        _unresolvedIntent = request;
      }
      emit(
        state.copyWith(
          hasUnresolvedRedemption: true,
          unresolvedRedPoints: request.redPoints,
        ),
      );
      Object? submissionError;
      try {
        await _repository.redeem(request);
      } catch (error) {
        submissionError = error;
      }
      if (!_current(scope, generation)) return;
      final api = submissionError is ApiException ? submissionError : null;
      final resolved = submissionError == null || _isConfirmedTerminal(api);
      var cleared = false;
      if (resolved) {
        try {
          await _intentStorage.clear(scope, request.clientRedemptionId);
          cleared = true;
        } catch (_) {}
        if (!_current(scope, generation)) return;
        if (cleared) _unresolvedIntent = null;
      }
      emit(
        state.copyWith(
          redeeming: false,
          redemptionSucceeded: submissionError == null,
          hasUnresolvedRedemption: !cleared,
          unresolvedRedPoints: cleared ? 0 : request.redPoints,
          canRetryRedemption: !cleared,
          partialFailure: submissionError != null
              ? _failure(submissionError)
              : !cleared
              ? const Failure(
                  message: 'Redemption succeeded, but its saved recovery record could not be cleared. Retry the same operation.',
                )
              : null,
          domainCode: api?.statusCode == 409 ? api?.code : null,
        ),
      );
      if (submissionError == null) {
        await load(refresh: true);
        if (_current(scope, generation)) {
          emit(state.copyWith(redemptionSucceeded: true));
        }
      }
    } finally {
      completion.complete();
      if (identical(_scopeOperations[scopeKey], completion.future)) {
        _scopeOperations.remove(scopeKey);
      }
      if (identical(_redemptionClaim, claim)) {
        _redemptionClaim = null;
        if (_current(scope, generation) && state.redeeming) {
          emit(state.copyWith(redeeming: false));
        }
      }
    }
  }

  // The backend checks the original key under the wallet lock before these
  // business rejections. Auth, rate limits, unknown responses and key/payload
  // conflicts do not resolve an uncertain logical operation.
  bool _isConfirmedTerminal(ApiException? error) =>
      error?.statusCode == 409 &&
      error?.kind == FailureKind.validation &&
      const {
        'POINTS_INSUFFICIENT_GREEN',
        'POINTS_INSUFFICIENT_RED',
        'POINTS_POLICY_DISABLED',
        'POINTS_COMPENSATION_DISABLED',
        'POINTS_MONTHLY_LIMIT_EXCEEDED',
      }.contains(error?.code);

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

  Failure _failure(Object error) => error is ApiException
      ? error.toFailure()
      : const Failure(message: 'Something went wrong. Please try again.');
  bool _current(FeatureSessionScope scope, int generation) =>
      !isClosed && _scope == scope && _generation == generation;
  bool _sameMonth(DateTime? left, DateTime right) =>
      left?.year == right.year && left?.month == right.month;
}
